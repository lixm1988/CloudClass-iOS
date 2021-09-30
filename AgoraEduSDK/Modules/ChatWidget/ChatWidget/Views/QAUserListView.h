//
//  QAUserListView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/9/9.
//

#import "QAView.h"
#import "ChatManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface QAUserListView : QAView
@property (nonatomic,weak) id parantView;
@property (nonatomic,weak) ChatManager* chatManager;
@end

NS_ASSUME_NONNULL_END
