//
//  MembersView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MembersView : UIView
@property (nonatomic,strong) NSArray* members;
@property (nonatomic,strong) NSArray* admins;
- (void)updateMembers:(NSArray*)aMembers admins:(NSArray*)admins;
@end

NS_ASSUME_NONNULL_END
