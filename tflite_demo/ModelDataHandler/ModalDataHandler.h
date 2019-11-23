//
//  ModalDataHandler.h
//  tflite_demo
//
//  Created by blackox626 on 2019/11/22.
//  Copyright © 2019 vdian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ModalDataHandler : NSObject

- (id)initWithModelPath:(NSString *)modelPath labelPath:(NSString *)labelPath;

@end

NS_ASSUME_NONNULL_END
