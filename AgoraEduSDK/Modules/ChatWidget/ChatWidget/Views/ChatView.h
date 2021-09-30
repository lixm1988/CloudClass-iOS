//
//  ChatView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/4.
//

#import <UIKit/UIKit.h>
#import <ChatBar.h>
#import <HyphenateChat/HyphenateChat.h>
#import "ChatManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ChatViewDelegate <NSObject>
- (void)chatViewDidClickAnnouncement;
- (void)msgWillSend:(NSString*)aMsgText;
- (void)imageDataWillSend:(NSData*)aImageData isQA:(BOOL)aIsQAMsg;
- (void)muteAllDidClick:(BOOL)aMuteAll;
@end

@interface NilMessageView : UIView
@end

@interface ShowAnnouncementView : UIView
@end

@interface ChatView : UIView
@property (nonatomic,weak) id<ChatViewDelegate> delegate;
@property (nonatomic,strong) NSString* announcement;
@property (nonatomic,strong) ChatBar* chatBar;
@property (nonatomic,weak) ChatManager* chatManager;
- (instancetype)initWithFrame:(CGRect)frame chatManager:(ChatManager*)chatManager;
- (void)updateMsgs:(NSMutableArray<EMMessage*>*)msgArray;
- (void)scrollToBottomRow;
- (void)muteStateChange;
@end

NS_ASSUME_NONNULL_END
