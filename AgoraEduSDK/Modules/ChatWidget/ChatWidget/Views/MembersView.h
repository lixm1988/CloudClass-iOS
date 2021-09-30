//
//  MembersView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/16.
//

#import <UIKit/UIKit.h>
#import "ChatManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MembersView : UIView
@property (nonatomic,strong) NSMutableArray* members;
@property (nonatomic,strong) NSMutableArray* admins;
@property (nonatomic,strong) NSMutableArray* muteMembers;
@property (nonatomic,weak) ChatManager* chatManager;
- (void)updateMembers:(NSArray*)aMembers admins:(NSArray*)admins;
- (void)updateMuteMembers:(NSArray*)muteMembers;
@end

NS_ASSUME_NONNULL_END
