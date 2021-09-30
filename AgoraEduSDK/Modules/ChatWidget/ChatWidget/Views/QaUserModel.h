//
//  QaUserModel.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/9/13.
//

#import <Foundation/Foundation.h>
#import <HyphenateChat/HyphenateChat.h>

NS_ASSUME_NONNULL_BEGIN

@interface QaUserModel : NSObject
@property (nonatomic,strong) NSString* userId;
@property (nonatomic,strong) NSMutableArray* msgArray;
- (void)pushMsg:(EMMessage*)msg;
@end

NS_ASSUME_NONNULL_END
