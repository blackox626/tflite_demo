//
//  ViewController.m
//  tflite_demo
//
//  Created by blackox626 on 2019/11/22.
//  Copyright © 2019 vdian. All rights reserved.
//

#import "ViewController.h"
#import "ModalDataHandler.h"

@interface ViewController ()

@end

@implementation ViewController {
    ModalDataHandler *_dataHander;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    NSString *model_path = [[NSBundle mainBundle] pathForResource:@"my_keras_model" ofType:@"tflite"];
    
    NSString *label_path = [[NSBundle mainBundle] pathForResource:@"labels" ofType:@"txt"];
    
    _dataHander = [[ModalDataHandler alloc] initWithModelPath:model_path labelPath:label_path];

    [_dataHander runModel:[UIImage imageNamed:@"plot"]];
}

@end
