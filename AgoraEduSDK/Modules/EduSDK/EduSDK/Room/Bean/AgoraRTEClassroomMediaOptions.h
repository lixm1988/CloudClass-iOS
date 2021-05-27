//
//  AgoraRTEClassroomMediaOptions.h
//  EduSDK
//
//  Created by SRS on 2020/7/3.
//  Copyright © 2020 agora. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AgoraRTEEnumerates.h"

NS_ASSUME_NONNULL_BEGIN

@interface AgoraRTEClassroomMediaOptions : NSObject

// default YES
@property (nonatomic, assign) BOOL autoSubscribe;

// default YES
@property (nonatomic, assign) BOOL autoPublish;

// default 0, it is generated by the background
// != 0, you need to control yourself
@property (nonatomic, assign) NSInteger primaryStreamId;

@end

NS_ASSUME_NONNULL_END
