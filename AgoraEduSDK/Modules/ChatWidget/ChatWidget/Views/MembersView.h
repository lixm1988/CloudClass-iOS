//
//  MembersView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MembersView : UIView
@property (nonatomic,strong) NSMutableArray* members;
@property (nonatomic,strong) NSMutableArray* admins;
- (void)updateMembers:(NSArray*)aMembers admins:(NSArray*)admins;
@end

NS_ASSUME_NONNULL_END
