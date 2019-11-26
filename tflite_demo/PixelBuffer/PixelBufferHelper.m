//
//  PixelBufferHelper.m
//  tflite_demo
//
//  Created by blackox626 on 2019/11/25.
//  Copyright © 2019 vdian. All rights reserved.
//

#import "PixelBufferHelper.h"
#import <Accelerate/Accelerate.h>

@implementation PixelBufferHelper

+ (UIImage *)Resize:(UIImage *)sourceImage toSize:(CGSize)targetSize {

    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        } else {
            scaleFactor = heightFactor; // scale to fit width
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else {
            if (widthFactor < heightFactor) {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();

    if (newImage == nil) {
        NSLog(@"could not scale image");
    }
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    CVImageBufferRef imageBuffer = pixelBufferRef;

    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);

    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return image;
}

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
    NSDictionary *options = @{
            (NSString *) kCVPixelBufferCGImageCompatibilityKey: @YES,
            (NSString *) kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
            (NSString *) kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
    };
    CVPixelBufferRef pxbuffer = NULL;

    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);

    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
            frameWidth,
            frameHeight,
            kCVPixelFormatType_32BGRA,
            (__bridge CFDictionaryRef) options,
            &pxbuffer);

    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef context = CGBitmapContextCreate(pxdata,
            frameWidth,
            frameHeight,
            8,
            CVPixelBufferGetBytesPerRow(pxbuffer),
            rgbColorSpace,
            (CGBitmapInfo) kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
            0,
            frameWidth,
            frameHeight),
            image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

    return pxbuffer;
}

+ (CVPixelBufferRef)centerThumbnail:(CVImageBufferRef)imageBuffer size:(CGSize)size {
    @synchronized (self) {
        //锁定图像缓冲区
        CVPixelBufferLockBaseAddress(imageBuffer, 0);

        //获取有关图像的信息
        uint8_t *baseAddress = (uint8_t *) CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);

        OSType pixelBufferType = CVPixelBufferGetPixelFormatType(imageBuffer);

        size_t thumbnailSize = MIN(width, height);

        size_t originX = 0;
        size_t originY = 0;

        if (width > height) {
            originX = (width - height) / 2;
        } else {
            originY = (height - width) / 2;
        }

        vImage_Buffer vimg_buffer = {.data = &baseAddress[originY * bytesPerRow + originX * 4], .height = thumbnailSize,
                .width = thumbnailSize, .rowBytes = bytesPerRow};

        size_t thumbnailRowBytes = (size_t) (size.width * 4);
        uint8_t *thumbnailBaseAddress = (uint8_t *) malloc((size_t) (size.height * thumbnailRowBytes));


        vImage_Buffer thumbnail_vimg_buffer = {.data =  thumbnailBaseAddress, .height =  (vImagePixelCount) size.height, .width =
        (vImagePixelCount) size.width, .rowBytes =  thumbnailRowBytes};

        vImage_Error error = vImageScale_ARGB8888(&vimg_buffer, &thumbnail_vimg_buffer, nil, kvImageNoFlags);

        if (error) {

        }

        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

        CVPixelBufferRef pxbuffer;

        CVReturn status = CVPixelBufferCreateWithBytes(
                kCFAllocatorDefault,
                (size_t) size.width,
                (size_t) size.height,
                pixelBufferType,
                thumbnailBaseAddress,
                thumbnailRowBytes,
                nil,
                nil,
                nil,
                &pxbuffer);

        if (status != 0) {
//            CKLog(@％d”,status);
//            返回NULL;
        }

        return pxbuffer;
    }
}

+ (UIImage *)convert:(CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];

    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
            createCGImage:ciImage
                 fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];

    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);

    return uiImage;
}

@end
