//
//  ChatView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/4.
//

#import <UIKit/UIKit.h>
#import <ChatBar.h>
#import <AgoraChat/AgoraChat.h>
#import "ChatManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ChatViewDelegate <NSObject>
- (void)chatViewDidClickAnnouncement;
- (void)msgWillSend:(NSString*)aMsgText;
@end

@interface NilMsgView : UIView
@end

@interface ShowAnnouncementView : UIView
@end

@interface ChatView : UIView
@property (nonatomic,weak) id<ChatViewDelegate> delegate;
@property (nonatomic,strong) NSString* announcement;
@property (nonatomic,strong) ChatBar* chatBar;
@property (nonatomic,weak) ChatManager* chatManager;
- (void)updateMsgs:(NSMutableArray<AgoraChatMessage*>*)msgArray;
- (void)scrollToBottomRow;
@end

NS_ASSUME_NONNULL_END
