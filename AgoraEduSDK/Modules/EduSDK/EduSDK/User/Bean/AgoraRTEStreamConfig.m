//
//  AgoraRTEStreamConfig.m
//  Demo
//
//  Created by SRS on 2020/6/24.
//  Copyright © 2020 agora. All rights reserved.
//

#import "AgoraRTEStreamConfig.h"

@implementation AgoraRTESubscribeOptions
@end

@implementation AgoraRTEStreamConfig
- (instancetype)initWithStreamUuid:(NSString *)streamUuid {
    
    if(self = [super init]){
        self.streamUuid = streamUuid;
        self.enableCamera = YES;
        self.enableMicrophone = YES;
    }
    return self;
}
@end
