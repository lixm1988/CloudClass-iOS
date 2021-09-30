//
//  QaUserCell.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/9/13.
//

#import <UIKit/UIKit.h>
#import "QaUserModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol QaUserCellDelegate <NSObject>

- (void)qaUserCellDidSelected:(UITableViewCell*)aCell;

@end

@interface QaUserCell : UITableViewCell
@property (nonatomic,strong) QaUserModel* model;
@property (nonatomic,weak) id<QaUserCellDelegate> delegate;
@property (nonatomic) BOOL showRedNotice;
- (instancetype)initWithUid:(NSString*)uid model:(QaUserModel *)model;
@end

NS_ASSUME_NONNULL_END
