//
//  ViewController.m
//  tflite_demo
//
//  Created by blackox626 on 2019/11/22.
//  Copyright © 2019 vdian. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "ModelDataHandler.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property(strong, nonatomic) AVCaptureSession *captureSession;
@property(strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property(strong, nonatomic) AVCaptureVideoDataOutput *dataOutput;

@end

@implementation ViewController {
    ModelDataHandler *_dataHander;
    NSTimeInterval _preInferTime;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _preInferTime = [[NSDate date] timeIntervalSince1970] *1000;
    
    [self initModalDataHandler];

    [self initAVCaptureSession];

    [self.captureSession startRunning];
}

- (void)initAVCaptureSession {
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
//                                                                 mediaType:AVMediaTypeVideo
//                                                                  position:AVCaptureDevicePositionBack];

    NSError *error = nil;
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (self.videoInput) {
        [self.captureSession addInput:self.videoInput];
    } else {
        NSLog(@"Input Error: %@", error);
    }

    dispatch_queue_t queue = dispatch_queue_create("sampleBufferQueue", NULL);

    self.dataOutput = [AVCaptureVideoDataOutput new];
    self.dataOutput.alwaysDiscardsLateVideoFrames = YES;
    //self.dataOutput.availableVideoCVPixelFormatTypes = [@(kCMPixelFormat_32BGRA)];
    self.dataOutput.videoSettings = @{(NSString *) kCVPixelBufferPixelFormatTypeKey: @(kCMPixelFormat_32BGRA)};
    [self.dataOutput setSampleBufferDelegate:self queue:queue];

    [self.captureSession addOutput:self.dataOutput];


    AVCaptureConnection *videoCon = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];

    //录制出来的视频是有90度转角的, 这是默认情况
    if ([videoCon isVideoOrientationSupported]) {
        videoCon.videoOrientation = AVCaptureVideoOrientationPortrait;
        // 下面这句是默认系统video orientation情况!!!!,如果要outputsample图片输出的方向是正的那么需要将这里设置称为portrait
        //videoCon.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }

    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.frame = self.view.bounds;
    //previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [self.view.layer addSublayer:previewLayer];
}

- (void)initModalDataHandler {
    NSString *model_path = [[NSBundle mainBundle] pathForResource:@"my_keras_model" ofType:@"tflite"];
    NSString *label_path = [[NSBundle mainBundle] pathForResource:@"labels" ofType:@"txt"];

    _dataHander = [[ModelDataHandler alloc] initWithModelPath:model_path labelPath:label_path];
    //[_dataHander runModel:[UIImage imageNamed:@"plot"]];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {

    NSTimeInterval _curInferTime = [[NSDate date] timeIntervalSince1970] *1000;
    
    if((_curInferTime - _preInferTime) < 1000) return;
    
    [_dataHander runModelWithPixel:CMSampleBufferGetImageBuffer(sampleBuffer)];
    
    _preInferTime = _curInferTime;
}

@end
