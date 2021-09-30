//
//  ChatBar.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/5.
//

#import <UIKit/UIKit.h>
#import "InputingView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ChatBarDelegate <NSObject>

- (void)msgWillSend:(NSString*)aMsgText;
- (void)imageDataWillSend:(NSData*)aImageData;

@end

@interface ChatBar : UIView
@property (nonatomic,weak) id<ChatBarDelegate> delegate;
@property (nonatomic,strong) UIButton* inputButton;
@property (nonatomic,strong) InputingView* inputingView;
@property (nonatomic) BOOL isAllMuted;
@property (nonatomic) BOOL isMuted;
@end

NS_ASSUME_NONNULL_END
