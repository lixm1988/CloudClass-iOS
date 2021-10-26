//
//  ChatView.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/4.
//

#import "ChatView.h"
#import "EMMessageModel.h"
#import "EMMessageStringCell.h"
#import "EMMessageCell.h"
#import "UIImage+ChatExt.h"
#import <Masonry/Masonry.h>
#import "EMDateHelper.h"
#import "ChatWidget+Localizable.h"
#import "ChatWidgetDefine.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CustomPopOverView.h"

#define CHATBAR_HEIGHT 30

@interface NilMessageView ()
@property (nonatomic,strong) UIImageView* nilMsgImageView;
@property (nonatomic,strong) UILabel* nilMsgLable;
@end

@implementation NilMessageView

- (instancetype)init
{
    self = [super init];
    if(self) {
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews
{
    self.nilMsgImageView = [[UIImageView alloc] init];
    self.nilMsgImageView.image = [UIImage imageNamedFromBundle:@"icon_nil"];
    [self addSubview:self.nilMsgImageView];
    [self.nilMsgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self);
        make.width.equalTo(@80);
        make.height.equalTo(@72);
    }];
    
    self.nilMsgLable = [[UILabel alloc] init];
    self.nilMsgLable.text = [ChatWidget LocalizedString:@"ChatEmptyText"];
    self.nilMsgLable.font = [UIFont systemFontOfSize:12];
    self.nilMsgLable.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.nilMsgLable];
    [self.nilMsgLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self);
        make.centerX.equalTo(self);
        make.height.equalTo(@20);
        make.width.equalTo(self);
    }];
}

@end

@interface ShowAnnouncementView ()
@property (nonatomic,strong) UIButton* announcementButton;
@property (nonatomic,weak) ChatView* parantView;
@end

@implementation ShowAnnouncementView

- (instancetype)init
{
    self = [super init];
    if(self) {
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews
{
    self.backgroundColor = [UIColor colorWithRed:253/255.0 green:249/255.0 blue:244/255.0 alpha:1.0];
    self.announcementButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.announcementButton setImage:[UIImage imageNamedFromBundle:@"icon_notice"] forState:UIControlStateNormal];
    [self.announcementButton setTitle:@"" forState:UIControlStateNormal];
    [self.announcementButton setTitleColor:[UIColor colorWithRed:25/255.0 green:25/255.0 blue:25/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.announcementButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    self.announcementButton.titleLabel.numberOfLines = 1;
    [self addSubview:self.announcementButton];
    self.announcementButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.announcementButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.announcementButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.height.equalTo(self);
        make.width.equalTo(self).with.multipliedBy(0.8);
    }];
    [self.announcementButton addTarget:self action:@selector(announcementAction) forControlEvents:UIControlEventTouchUpInside];
}

- (void)announcementAction
{
    if(self.parantView.delegate) {
        [self.parantView.delegate chatViewDidClickAnnouncement];
    }
}

@end

@interface ChatView ()<UITableViewDelegate, UITableViewDataSource, ChatBarDelegate,EMMessageCellDelegate,EMMessageStringCellDelegate,CustomPopOverViewDelegate>
@property (nonatomic,strong) NilMessageView* nilMessageView;
@property (strong, nonatomic) UITableView *tableView;
@property (nonatomic,strong) ShowAnnouncementView* showAnnouncementView;
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, nonatomic) NSMutableArray *msgIdArray;
//消息格式化
@property (nonatomic) NSTimeInterval msgTimelTag;
//长按操作栏
@property (strong, nonatomic) NSIndexPath *menuIndexPath;
// 删除的消息
@property (nonatomic, strong) NSMutableArray<NSString*>* msgsToDel;
// 全员禁言按钮
@property (nonatomic,strong) UIButton* muteAllButton;
// 图片放大
@property (nonatomic,strong) UIImageView* fullImageView;
// 菜单style
@property (nonatomic,strong) CPShowStyle *menuStyle;
// 新消息按钮
@property (nonatomic, strong) UIButton* newMsgsButton;
// 消息列表是否在最底部
@property (nonatomic) BOOL curMsgInBottom;
// 新消息条数统计
@property (atomic) NSUInteger newMsgsCount;
@end

@implementation ChatView

- (instancetype)initWithFrame:(CGRect)frame chatManager:(ChatManager*)chatManager
{
    self = [super initWithFrame:frame];
    if(self) {
        self.msgTimelTag = -1;
        self.chatManager = chatManager;
        self.curMsgInBottom = YES;
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews
{
    self.backgroundColor = [UIColor whiteColor];
    self.nilMessageView = [[NilMessageView alloc] init];
    [self addSubview:self.nilMessageView];
    [self.nilMessageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@100);
        make.centerX.equalTo(self);
        make.centerY.equalTo(self).offset(-CHATBAR_HEIGHT/2);
    }];
    
    self.showAnnouncementView = [[ShowAnnouncementView alloc] init];
    self.showAnnouncementView.parantView = self;
    [self addSubview:self.showAnnouncementView];
    self.showAnnouncementView.hidden = YES;
    [self.showAnnouncementView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self);
        make.top.equalTo(self);
        make.left.equalTo(self);
        make.height.equalTo(@24);
    }];
    [self bringSubviewToFront:self.showAnnouncementView];
    
    [self addSubview:self.tableView];
    
    self.chatBar = [[ChatBar alloc] init];
    self.chatBar.delegate = self;
    [self addSubview:self.chatBar];
    [self sendSubviewToBack:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.equalTo(self);
        make.top.width.equalTo(self).offset(24);
        make.bottom.equalTo(self).offset(-40);
    }];
    if(!ROLE_IS_TEACHER(self.chatManager.user.role)) {
        [self.chatBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self).offset(-10);
            make.height.equalTo(@CHATBAR_HEIGHT);
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self).offset(-10);
        }];
        self.chatBar.layer.cornerRadius = 15;
    }else{
        [self.chatBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self).offset(-5);
            make.height.equalTo(@CHATBAR_HEIGHT);
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self).offset(-50);
        }];
        self.chatBar.layer.cornerRadius = 15;
        
        [self addSubview:self.muteAllButton];
        [self.muteAllButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@30);
            make.centerY.equalTo(self.chatBar);
            make.right.equalTo(self).offset(-10);
        }];
    }
    
    [self addSubview:self.newMsgsButton];
    [self.newMsgsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.tableView);
        make.bottom.equalTo(self.tableView).offset(-10);
        make.width.equalTo(@110);
        make.height.equalTo(@22);
    }];
    [self bringSubviewToFront:self.newMsgsButton];
}

- (void)setAnnouncement:(NSString *)announcement
{
    _announcement = announcement;
    self.showAnnouncementView.hidden = _announcement.length == 0;
//    announcement = [announcement stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
//    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
//    NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
//    NSArray *parts = [announcement componentsSeparatedByCharactersInSet:whitespaces];
//    NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
//    announcement = [filteredArray componentsJoinedByString:@" "];

    [self.showAnnouncementView.announcementButton setTitle:announcement forState:UIControlStateNormal];
}

//- (void)layoutSubviews
//{
//    [super layoutSubviews];
////    self.tableView.frame = CGRectMake(0, 0, self.bounds.size.width,self.bounds.size.height - 40);
////    self.chatBar.frame = CGRectMake(0, self.bounds.size.height - 40, self.bounds.size.width, 40);
//}

#pragma mark - getter

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableFooterView = [UIView new];
    }
    
    return _tableView;
}

- (NSMutableArray *)dataArray
{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
    }
    
    return _dataArray;
}

- (UIButton*)muteAllButton
{
    if(!_muteAllButton) {
        _muteAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _muteAllButton.layer.cornerRadius = 15;
        _muteAllButton.layer.borderWidth = 1;
        _muteAllButton.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);
        _muteAllButton.contentMode = UIViewContentModeScaleAspectFit;
        _muteAllButton.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
        _muteAllButton.backgroundColor = [UIColor colorWithRed:249/255.0 green:249/255.0 blue:252/255.0 alpha:1.0];
        [_muteAllButton setImage:[UIImage imageNamedFromBundle:@"icon_mute"] forState:UIControlStateNormal];
        [_muteAllButton setImage:[UIImage imageNamedFromBundle:@"icon_unmute"] forState:UIControlStateSelected];
        [_muteAllButton addTarget:self action:@selector(muteAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _muteAllButton;
}

- (void)muteAction
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(muteAllDidClick:)]) {
        [self.delegate muteAllDidClick:!self.muteAllButton.isSelected];
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (NSMutableArray<NSString*>*)msgsToDel
{
    if(!_msgsToDel) {
        _msgsToDel = [NSMutableArray<NSString*> array];
    }
    return _msgsToDel;
}

- (UIButton*)newMsgsButton
{
    if(!_newMsgsButton) {
        _newMsgsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_newMsgsButton setTitle:[ChatWidget LocalizedString:@"ChatNewMsgs"] forState:UIControlStateNormal];
        [_newMsgsButton addTarget:self action:@selector(newMsgsAction) forControlEvents:UIControlEventTouchUpInside];
        _newMsgsButton.hidden = YES;
        _newMsgsButton.layer.cornerRadius = 10;
        _newMsgsButton.layer.borderWidth = 1;
        _newMsgsButton.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
        _newMsgsButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
        _newMsgsButton.backgroundColor = [UIColor whiteColor];
        _newMsgsButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _newMsgsButton.imageEdgeInsets = UIEdgeInsetsMake(2, 10, 2, 86);
        [_newMsgsButton setImage:[UIImage imageNamedFromBundle:@"icon_hide"] forState:UIControlStateNormal];
        _newMsgsButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_newMsgsButton setTintColor:[UIColor colorWithRed:53/255.0 green:123/255.0 blue:246/255.0 alpha:1.0]];
        _newMsgsButton.layer.shadowColor = [UIColor colorWithRed:47/255.0 green:65/255.0 blue:146/255.0 alpha:0.15].CGColor;
        _newMsgsButton.layer.shadowOffset = CGSizeMake(0,0);
        _newMsgsButton.layer.shadowOpacity = 1;
        _newMsgsButton.layer.shadowRadius = 5;
    }
    return _newMsgsButton;
}

- (void)newMsgsAction
{
    [self scrollToBottomRow];
    self.newMsgsCount = 0;
    self.newMsgsButton.hidden = YES;
}

#pragma mark - UITableViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat height = scrollView.frame.size.height;
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    CGFloat bottomOffset = scrollView.contentSize.height - contentOffsetY;
    if (bottomOffset <= height)
    {
        self.curMsgInBottom = YES;
        self.newMsgsButton.hidden = YES;
        self.newMsgsCount = 0;
    }else
    {
        self.curMsgInBottom = NO;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id obj = [self.dataArray objectAtIndex:indexPath.row];
    NSString* recallMsgId = @"";
    NSString *cellString = nil;
    if ([obj isKindOfClass:[NSString class]]) {
        cellString = (NSString *)obj;
    } else if ([obj isKindOfClass:[EMMessageModel class]]) {
        EMMessageModel *model = (EMMessageModel *)obj;
        if (model.type == EMMessageTypeExtRecall) {
            cellString = [ChatWidget LocalizedString:@"ChatRecallAMessage"];
        }
        if (model.emModel.body.type == AgoraChatMessageBodyTypeCmd) {
            AgoraChatCmdMessageBody* cmdBody = (AgoraChatCmdMessageBody*)model.emModel.body;
            NSString*action = cmdBody.action;
            NSDictionary* ext = model.emModel.ext;
            if([action isEqualToString:@"DEL"]) {
                NSString* msgId = [ext objectForKey:@"msgId"];
                NSLog(@"msgIdToDel:%@",msgId);
                BOOL isRecall = NO;
                if(msgId.length > 0) {
                    AgoraChatMessage* msgToDel = [[[AgoraChatClient sharedClient] chatManager] getMessageWithMessageId:msgId];
                    if(msgToDel) {
                        if([msgToDel.from isEqualToString:model.emModel.from]) {
                            isRecall = YES;
                            recallMsgId = msgId;
                        }
                    }
                }
                if(isRecall)
                    cellString = [NSString stringWithFormat:@"%@ %@",model.emModel.from,[ChatWidget LocalizedString:@"ChatUserRecallMsg"] ];
                else
                    cellString = [ChatWidget LocalizedString:@"ChatTeacherRemoveMsg"];
            }
            if([action isEqualToString:@"setAllMute"]) {
                cellString = [ChatWidget LocalizedString:@"ChatTeacherMuteAll"];
            }
            if([action isEqualToString:@"removeAllMute"]) {
                cellString = [ChatWidget LocalizedString:@"ChatTeacherUnmuteAll"];
            }
            if([action isEqualToString:@"mute"] || [action isEqualToString:@"unmute"]) {
                NSString* muteMember = [ext objectForKey:@"muteMember"];
                
                if(muteMember.length > 0 && [[AgoraChatClient sharedClient].currentUsername isEqualToString:muteMember]) {
                    NSString* muteNickname = [ext objectForKey:@"muteNickName"];
                    NSString* teacherNickName = [ext objectForKey:@"nickName"];
                    if([action isEqualToString:@"mute"]) {
                        cellString = [NSString stringWithFormat: [ChatWidget LocalizedString:@"ChatMutedByTeacher"],teacherNickName];
                    }else{
                        cellString = [NSString stringWithFormat: [ChatWidget LocalizedString:@"ChatUnmutedByTeacher"],teacherNickName];
                    }
                    
                }
            }
        }
    }
    if ([cellString length] > 0) {
        EMMessageStringCell *cell = (EMMessageStringCell *)[tableView dequeueReusableCellWithIdentifier:@"EMMessageTimeCell"];
        // Configure the cell...
        if (cell == nil) {
            cell = [[EMMessageStringCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EMMessageTimeCell"];
        }

        [cell updatetext:cellString];
        cell.recallMsgId = recallMsgId;
        if(recallMsgId.length > 0) {
            cell.delegate = self;
        }
        return cell;
    } else {
        EMMessageModel *model = (EMMessageModel *)obj;
        NSString *identifier = [EMMessageCell cellIdentifierWithDirection:model.direction type:model.type];
        // Configure the cell...
        EMMessageCell *cell = (EMMessageCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil) {
            cell = [[EMMessageCell alloc] initWithDirection:model.direction type:model.type];
            cell.delegate = self;
        }
        cell.model = model;
        return cell;
    }
}

- (void)removDelMsg:(NSString*)aDelMsgId fromArray:(NSMutableArray*)array
{
    NSEnumerator *enumerator = [array reverseObjectEnumerator];
    //forin遍历
    for (EMMessageModel *model in enumerator) {
        if([model.emModel.messageId isEqualToString:aDelMsgId]) {
            [array removeObject:model];
        }
    }
}

-(NSMutableArray*)msgIdArray
{
    if(!_msgIdArray) {
        _msgIdArray = [NSMutableArray array];
    }
    return _msgIdArray;
}

- (NSArray *)_formatMessages:(NSArray<AgoraChatMessage *> *)aMessages
{
    NSMutableArray *formated = [[NSMutableArray alloc] init];

    for (int i = 0; i < [aMessages count]; i++) {
        AgoraChatMessage *msg = aMessages[i];
        if([self.msgIdArray containsObject:msg.messageId]) {
            continue;
        }else{
            [self.msgIdArray addObject:msg.messageId];
        }

        // cmd消息不展示
        if(msg.body.type == AgoraChatMessageBodyTypeCmd) {
            AgoraChatCmdMessageBody* cmdBody = (AgoraChatCmdMessageBody*)msg.body;
            if([cmdBody.action isEqualToString:@"DEL"]) {
                NSString* msgIdToDel = [msg.ext objectForKey:@"msgId"];
                if(msgIdToDel.length > 0) {
                    [self.msgsToDel addObject:msgIdToDel];
                    [self removDelMsg:msgIdToDel fromArray:formated];
                    [self removDelMsg:msgIdToDel fromArray:self.dataArray];
                }
            }else if(!( [cmdBody.action isEqualToString:@"setAllMute"] || [cmdBody.action isEqualToString:@"removeAllMute"])){
                if([cmdBody.action isEqualToString:@"mute"] || [cmdBody.action isEqualToString:@"unmute"]) {
                    NSString* muteMember = [msg.ext objectForKey:@"muteMember"];
                    if(![[AgoraChatClient sharedClient].currentUsername isEqualToString:muteMember])
                        continue;
                }else
                    continue;
            }
        }
        if(msg.body.type == AgoraChatMessageBodyTypeCustom) {
            continue;
        }
        if (msg.chatType == AgoraChatTypeChat && !msg.isReadAcked && (msg.body.type == AgoraChatMessageBodyTypeText || msg.body.type == AgoraChatMessageBodyTypeLocation)) {
            if([self.msgsToDel containsObject:msg.messageId])
                continue;
            [[AgoraChatClient sharedClient].chatManager sendMessageReadAck:msg.messageId toUser:msg.conversationId completion:nil];
        } else if (msg.chatType == AgoraChatTypeGroupChat && !msg.isReadAcked && (msg.body.type == AgoraChatMessageBodyTypeText || msg.body.type == AgoraChatMessageBodyTypeLocation)) {
        }
        
        CGFloat interval = (self.msgTimelTag - msg.timestamp) / 1000;
        if (self.msgTimelTag < 0 || interval > 60 || interval < -60) {
            NSString *timeStr = [EMDateHelper formattedTimeFromTimeInterval:msg.timestamp];
            //[formated addObject:timeStr];
            self.msgTimelTag = msg.timestamp;
        }
        
        EMMessageModel *model = [[EMMessageModel alloc] initWithEMMessage:msg];
        [formated addObject:model];
    }
    
    return formated;
}

- (void)scrollToBottomRow
{
    if ([self.dataArray count] > 0) {
        [self.tableView setNeedsLayout];
        [self.tableView layoutIfNeeded];
        NSInteger toRow = self.dataArray.count - 1;
        NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:toRow inSection:0];
        __weak typeof(self) weakself = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakself.tableView scrollToRowAtIndexPath:toIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            weakself.curMsgInBottom = YES;
        });
    }
}

- (void)updateMsgs:(NSMutableArray<AgoraChatMessage*>*)msgArray
{
    NSArray *formated = [self _formatMessages:msgArray];
    [self.dataArray addObjectsFromArray:formated];
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself.tableView reloadData];
        if(weakself.dataArray.count > 0){
            weakself.nilMessageView.hidden = YES;
        }
        if(!weakself.curMsgInBottom)
        {
            weakself.newMsgsButton.hidden = NO;
            weakself.newMsgsCount += formated.count;
            [weakself.newMsgsButton setTitle:[NSString stringWithFormat:@"%d %@",weakself.newMsgsCount,[ChatWidget LocalizedString:@"ChatNewMsgs"]] forState:UIControlStateNormal];
        }
        else{
            [weakself scrollToBottomRow];
        }
    });
}

- (void)muteStateChange
{
    if(ROLE_IS_TEACHER(self.chatManager.user.role)) {
        self.muteAllButton.selected = self.chatManager.isAllMuted;
    }
}

- (UIImageView*)fullImageView
{
    if(!_fullImageView) {
        _fullImageView = [[UIImageView alloc] init];
        _fullImageView.userInteractionEnabled = YES;
        _fullImageView.multipleTouchEnabled = YES;
        _fullImageView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
        _fullImageView.contentMode = UIViewContentModeScaleAspectFit;
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(handleTapAction:)];
        [_fullImageView addGestureRecognizer:tap];
        [self addGestureRecognizerToView:_fullImageView];
    }
    return _fullImageView;
}

- (void) addGestureRecognizerToView:(UIView *)view
{
    // 缩放手势
     UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];

    [view addGestureRecognizer:pinchGestureRecognizer];
}

// 处理缩放手势
 - (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    UIView *view = pinchGestureRecognizer.view;

    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged)

    {

     view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);          pinchGestureRecognizer.scale = 1;

     }
}

- (void)handleTapAction:(UITapGestureRecognizer *)aTap
{
    if (aTap.state == UIGestureRecognizerStateEnded) {
        [self.fullImageView removeFromSuperview];
    }
}

#pragma mark - ChatBarDelegate
- (void)msgWillSend:(NSString *)aMsgText
{
    self.curMsgInBottom = YES;
    [self scrollToBottomRow];
    [self.delegate msgWillSend:aMsgText];
}

#pragma mark - EMMessageCellDelegate
- (void)messageCellDidSelected:(EMMessageCell *)aCell
{
    // 图片消息需要点击放大
    if(aCell.model.emModel) {
        if(aCell.model.emModel.body.type == EMMessageTypeImage) {
            UIWindow * window=[[[UIApplication sharedApplication] delegate] window];
            AgoraChatImageMessageBody* imageBody = (AgoraChatImageMessageBody*)aCell.model.emModel.body;
            if(imageBody.remotePath.length > 0) {
                NSURL* url = [NSURL URLWithString:imageBody.remotePath];
                if(url) {
                    [self.fullImageView sd_setImageWithURL:url completed:nil];
                    [window addSubview:self.fullImageView];
                    self.fullImageView.frame = window.frame;
                }
            }
        }
    }
}

- (void)messageCellDidLongPress:(EMMessageCell *)aCell
{
    NSString* title = nil;
    if (aCell.model.emModel.direction == AgoraChatMessageDirectionSend) {
        title = [ChatWidget LocalizedString:@"ChatRecall"];
    }else{
        if(ROLE_IS_TEACHER(self.chatManager.user.role)){
            title = [ChatWidget LocalizedString:@"ChatRemove"];
        }else
            return;
    }
    NSArray *arr = @[
                     @{@"name": title, @"icon": @"icon_recall"}
                     ];
    
    CustomPopOverView *view = [[CustomPopOverView alloc]initWithBounds:CGRectMake(0, 0, 70, 30) titleInfo:arr style:self.menuStyle];
    view.delegate = self;
    [view showFrom:aCell.bubbleView alignStyle:CPAlignStyleCenter relativePosition:CPContentPositionAlwaysUp];
    self.menuIndexPath = [self.tableView indexPathForCell:aCell];
    //[self _showMenuViewController:aCell model:aCell.model isAvatar:NO];
}

- (void)messageCellDidResend:(EMMessageModel *)aModel
{
    
}

- (void)messageReadReceiptDetil:(EMMessageCell *)aCell
{
    
}

- (void)messageCellDidLongPressAvatar:(EMMessageCell *)aCell gestureRecognizer:(UILongPressGestureRecognizer*)gestureRecognizer
{
    if([self.chatManager.admins containsObject:aCell.model.emModel.from])
        return;
    self.menuIndexPath = [self.tableView indexPathForCell:aCell];
    
    NSString* title = nil;
    NSInteger width = 60;
    if([self.chatManager.muteMembers containsObject: aCell.model.emModel.from]) {
        title = [ChatWidget LocalizedString:@"ChatUnmute"];
        width = 90;
    }else{
        title = [ChatWidget LocalizedString:@"ChatMute"];
    }
    NSArray *arr = @[
                     @{@"name": title, @"icon": @"icon_mute"}
                     ];
    
    CustomPopOverView *view = [[CustomPopOverView alloc]initWithBounds:CGRectMake(0, 0, width, 30) titleInfo:arr style:self.menuStyle];
    view.delegate = self;
    [view showFrom:aCell.avatarView alignStyle:CPAlignStyleCenter relativePosition:CPContentPositionAlwaysUp];
    self.menuIndexPath = [self.tableView indexPathForCell:aCell];
}

- (CPShowStyle*)menuStyle
{
    if(!_menuStyle) {
        _menuStyle = [CPShowStyle new];
        _menuStyle.triAngelHeight = 6.0;
        _menuStyle.triAngelWidth = 10.0;
        _menuStyle.containerCornerRadius = 1.0;
        _menuStyle.containerBorderWidth = 0.0;
        _menuStyle.shadowColor = [UIColor grayColor];
        _menuStyle.roundMargin = 0.0;
        _menuStyle.defaultRowHeight = 30;
        _menuStyle.showSpace = 0;
        _menuStyle.tableBackgroundColor = [UIColor whiteColor];
        _menuStyle.containerBackgroudColor = [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0];
        _menuStyle.textColor = [UIColor colorWithRed:125/255.0 green:135/255.0 blue:152/255.0 alpha:1.0];
        _menuStyle.textAlignment = NSTextAlignmentLeft;
        _menuStyle.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _menuStyle;
}

- (void)imageDataWillSend:(NSData*)aImageData
{
    [self.delegate imageDataWillSend:aImageData isQA:NO];
}

#pragma mark - EMMessageCellStringDelegate
- (void)reeditMsgId:(NSString *)aMsgId
{
    if(!ROLE_IS_TEACHER(self.chatManager.user.role) && (self.chatBar.isMuted || self.chatBar.isAllMuted))
        return;
        
    if(aMsgId.length > 0) {
        AgoraChatMessage* msg = [[[AgoraChatClient sharedClient] chatManager] getMessageWithMessageId:aMsgId];
        if(msg.body.type == EMMessageTypeText) {
            AgoraChatTextMessageBody* textBody = (AgoraChatTextMessageBody*)msg.body;
            [self.chatBar.inputButton setTitle:textBody.text forState:UIControlStateNormal];
            self.chatBar.inputingView.inputTextView.text = textBody.text;
        }
        if([self.chatBar respondsToSelector:@selector(InputAction)])
            [self.chatBar performSelector:@selector(InputAction)];
    }
}

#pragma mark - CustomPopOverViewDelegate
- (void)popOverView:(CustomPopOverView *)pView didClickMenuTitle:(NSString*)title
{
    if([title isEqualToString:[ChatWidget LocalizedString:@"ChatMute"]]) {
        NSIndexPath *indexPath = self.menuIndexPath;
        EMMessageModel *model = [self.dataArray objectAtIndex:self.menuIndexPath.row];
        [self.chatManager muteMember:model.emModel.from mute:YES];
        self.menuIndexPath = nil;
    }
    if([title isEqualToString:[ChatWidget LocalizedString:@"ChatUnmute"]]) {
        NSIndexPath *indexPath = self.menuIndexPath;
        EMMessageModel *model = [self.dataArray objectAtIndex:self.menuIndexPath.row];
        [self.chatManager muteMember:model.emModel.from mute:NO];
        self.menuIndexPath = nil;
    }
    if([title isEqualToString:[ChatWidget LocalizedString:@"ChatRecall"]]) {
        EMMessageModel *model = [self.dataArray objectAtIndex:self.menuIndexPath.row];
        [self.chatManager deleteMessage:model.emModel.messageId];
        self.menuIndexPath = nil;
    }
    if([title isEqualToString:[ChatWidget LocalizedString:@"ChatRemove"]]) {
        EMMessageModel *model = [self.dataArray objectAtIndex:self.menuIndexPath.row];
        [self.chatManager deleteMessage:model.emModel.messageId];
        self.menuIndexPath = nil;
    }
    [pView removeFromSuperview];
    pView = nil;
}

@end
