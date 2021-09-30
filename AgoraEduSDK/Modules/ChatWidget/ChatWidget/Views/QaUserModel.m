//
//  QaUserModel.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/9/13.
//

#import "QaUserModel.h"

@implementation QaUserModel
- (NSMutableArray*)msgArray
{
    if(!_msgArray) {
        _msgArray = [NSMutableArray array];
    }
    return _msgArray;
}

- (void)pushMsg:(EMMessage*)msg
{
    if(self.msgArray.count == 0)
        [self.msgArray addObject:msg];
    else{
        EMMessage* lastMsg = [self.msgArray lastObject];
        if(msg.timestamp >= lastMsg.timestamp)
            [self.msgArray addObject:msg];
        else
            [self.msgArray insertObject:msg atIndex:0];
    }
}

@end
