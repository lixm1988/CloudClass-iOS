//
//  MsgView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/16.
//

#import <UIKit/UIKit.h>
#import <HyphenateChat/HyphenateChat.h>
#import "ChatWidgetDefine.h"
#import "ChatBar.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MsgViewDelegate <NSObject>
- (void)msgWillSend:(NSString*)aMsgText type:(ChatMsgType)aMsgType;
- (void)imageDataWillSend:(NSData*)aImageData isQA:(BOOL)aIsQAMsg;
@end

@interface MsgView : UIView<ChatBarDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,weak) id<MsgViewDelegate> delegate;
@property (nonatomic,strong) ChatBar* chatBar;
- (void)updateMsgs:(NSMutableArray<EMMessage*>*)msgArray;
- (void)scrollToBottomRow;
@end

NS_ASSUME_NONNULL_END
