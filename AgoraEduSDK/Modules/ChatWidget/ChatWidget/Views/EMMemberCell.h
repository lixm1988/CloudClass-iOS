//
//  EMMemberCell.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/22.
//

#import <UIKit/UIKit.h>
#import "MembersView.h"

NS_ASSUME_NONNULL_BEGIN

@interface EMMemberCell : UITableViewCell
@property (nonatomic,strong) NSString* userId;
@property (nonatomic,weak) MembersView* membersView;
- (instancetype)initWithUid:(NSString*)aUid;
- (void)setAvartarUrl:(NSString*)aUrl nickName:(NSString*)nickName role:(NSUInteger)role;
@end

NS_ASSUME_NONNULL_END
