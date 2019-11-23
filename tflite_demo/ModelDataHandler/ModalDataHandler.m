//
//  ModalDataHandler.m
//  tflite_demo
//
//  Created by blackox626 on 2019/11/22.
//  Copyright © 2019 vdian. All rights reserved.
//

#import "ModalDataHandler.h"
#import "TFLTensorFlowLite.h"

@implementation ModalDataHandler {
    NSString *_modelPath;
    NSString *_labelPath;
    
    TFLInterpreter *_interpreter;
    NSArray<NSString *> *_labels;
}

- (id)initWithModelPath:(NSString *)modelPath labelPath:(NSString *)labelPath {
    self = [super init];
    if(self) {
        _modelPath = modelPath;
        _labelPath = labelPath;
        
        [self initInterpreter];
    }
    return self;
}

- (void)initInterpreter {
    TFLInterpreterOptions *option = [[TFLInterpreterOptions alloc] init];
    option.numberOfThreads = 4;
    _interpreter = [[TFLInterpreter alloc] initWithModelPath:_modelPath options:option error:nil];
    [self loadLabels];
}

- (void)loadLabels {
    NSString *labels = [NSString stringWithContentsOfFile:_labelPath encoding:NSUTF8StringEncoding error:nil];
    _labels = [labels componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
}

@end
