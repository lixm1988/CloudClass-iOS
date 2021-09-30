//
//  AnnouncementView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AnnouncementViewDelegate <NSObject>

- (void)PublishAnnouncement:(NSString*)aText;

@end

@interface NilAnnouncementView : UIView
@end

@interface EditAnnouncementView : UIView
@end

@interface AnnouncementView : UIView
- (instancetype)initWithFrame:(CGRect)frame role:(NSInteger)role;
@property (nonatomic,strong) NSString* announcement;
@property (nonatomic) NSInteger role;
@property (nonatomic,weak) id<AnnouncementViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
