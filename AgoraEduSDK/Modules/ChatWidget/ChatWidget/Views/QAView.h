//
//  QAView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/16.
//

#import <UIKit/UIKit.h>
#import <HyphenateChat/HyphenateChat.h>
#import "ChatWidgetDefine.h"
#import "ChatBar.h"

NS_ASSUME_NONNULL_BEGIN

@protocol QAViewDelegate <NSObject>
- (void)msgWillSend:(NSString*)aMsgText type:(ChatMsgType)aMsgType asker:(NSString*)asker;
- (void)imageDataWillSend:(NSData*)aImageData type:(ChatMsgType)aMsgType asker:(NSString*)asker;
@end


@interface NilQAMessagesView : UIView

@end

@interface QAView : UIView<ChatBarDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,weak) id<QAViewDelegate> delegate;
@property (nonatomic,strong) ChatBar* chatBar;
@property (nonatomic,strong) NSString* asker;
- (void)updateMsgs:(NSMutableArray<EMMessage*>*)msgArray;
- (void)resetMsgs;
@end

NS_ASSUME_NONNULL_END
