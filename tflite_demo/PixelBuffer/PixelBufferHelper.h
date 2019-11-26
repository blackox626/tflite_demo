//
//  PixelBufferHelper.h
//  tflite_demo
//
//  Created by blackox626 on 2019/11/25.
//  Copyright © 2019 vdian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelBufferHelper : NSObject

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image;

+ (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef;

+ (CVPixelBufferRef)centerThumbnail:(CVImageBufferRef)imageBuffer size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
