//
//  ModelDataHandler.m
//  tflite_demo
//
//  Created by blackox626 on 2019/11/22.
//  Copyright © 2019 vdian. All rights reserved.
//

#import "ModelDataHandler.h"
#import "TFLTensorFlowLite.h"
#import "TFLInterpreter+Internal.h"
#import "PixelBufferHelper.h"

void quicksort(float arr[], int low, int high) {
    if (low >= high)
        return;
    int i = low;
    int j = high;
    float val = arr[j];
    while (i < j) {
        while (i < j && arr[i] >= val)
            i++;
        arr[j] = arr[i];
        while (i < j && arr[j] < val)
            j--;
        arr[i] = arr[j];
    }
    arr[i] = val;
    quicksort(arr, low, i - 1);
    quicksort(arr, i + 1, high);
}

@implementation ModelDataHandler {
    NSString *_modelPath;
    NSString *_labelPath;

    TFLInterpreter *_interpreter;
    NSArray<NSString *> *_labels;
    
    BOOL _saved;
}

- (id)initWithModelPath:(NSString *)modelPath labelPath:(NSString *)labelPath {
    self = [super init];
    if (self) {
        _saved = NO;
        _modelPath = modelPath;
        _labelPath = labelPath;

        [self initInterpreter];
    }
    return self;
}

- (void)initInterpreter {
    TFLInterpreterOptions *option = [[TFLInterpreterOptions alloc] init];
    option.numberOfThreads = 4;
    NSError *error = nil;
    _interpreter = [[TFLInterpreter alloc] initWithModelPath:_modelPath options:option error:&error];
    [self loadLabels];
}

- (void)loadLabels {
    NSString *labels = [NSString stringWithContentsOfFile:_labelPath encoding:NSUTF8StringEncoding error:nil];
    _labels = [labels componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"error %@", error);
}

- (void)runModel:(UIImage *)image {
    CVPixelBufferRef buffer = [PixelBufferHelper pixelBufferFromCGImage:image.CGImage];
    [self runModelWithPixel:buffer];
}

- (void)runModelWithPixel:(CVPixelBufferRef)pixbuffer {
    
    pixbuffer = [PixelBufferHelper centerThumbnail:pixbuffer];
    
    if(!_saved) {
        _saved = YES;
        UIImageWriteToSavedPhotosAlbum([PixelBufferHelper imageFromPixelBuffer:pixbuffer], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        
    }
    
    NSData *data = [ModelDataHandler dataWithPixelBuffer:pixbuffer];
    NSError *error = nil;
    [_interpreter allocateTensorsWithError:&error];

    TFLTensor *inputTensor = [_interpreter inputTensorAtIndex:0 error:&error];

    [_interpreter copyData:data toInputTensorAtIndex:0 error:&error];

    BOOL re = [_interpreter invokeWithError:&error];
    if (re) {}

    TFLTensor *outputTensor = [_interpreter outputTensorAtIndex:0 error:&error];

    NSData *predict = [outputTensor dataWithError:&error];

    float *pf = (float *) predict.bytes;

    //quicksort(pf, 0, 9);

    int index = 0;

    for (int i = 1; i < 10; i++) {
        if (pf[i] > pf[index]) {
            index = i;
        }

        printf("proba %f \n", pf[i]);
    }

    NSLog(@"%@ , %f", _labels[index], pf[index]);

    NSLog(@"%lu", (unsigned long) outputTensor.dataType);
}

+ (NSData *)dataWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {

    size_t count = CVPixelBufferGetDataSize(pixelBuffer);

    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    float *buffer = malloc(width * height * sizeof(float));

    [self copyDataFromPixelBuffer:pixelBuffer toBuffer:buffer];

    NSData *retData = [NSData dataWithBytes:buffer length:sizeof(float) * (width * height)];
    free(buffer);
    buffer = nil;
    return retData;
}

+ (void)copyDataFromPixelBuffer:(CVPixelBufferRef)pixelBuffer toBuffer:(float *)buffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    size_t w = CVPixelBufferGetWidth(pixelBuffer);
    size_t h = CVPixelBufferGetHeight(pixelBuffer);

    size_t d = CVPixelBufferGetBytesPerRow(pixelBuffer);

    unsigned char *src = (unsigned char *) CVPixelBufferGetBaseAddress(pixelBuffer);
    float *dst = buffer;

    int index = 0;

    OSType pixelBufferType = CVPixelBufferGetPixelFormatType(pixelBuffer);

    //memcpy(dst, src, h*d);
    for (int i = 0; i < h * d; i += 4) {
        int a = src[i + 3];
        int r = src[i + 2];
        int g = src[i + 1];
        int b = src[i];

        dst[index] = r / 255.0f;
        index++;
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

@end
