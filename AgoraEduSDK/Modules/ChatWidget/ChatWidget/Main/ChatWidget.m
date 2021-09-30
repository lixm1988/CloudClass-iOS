//
//  ChatWidget.m
//  AgoraEducation
//
//  Created by lixiaoming on 2021/5/12.
//  Copyright © 2021 Agora. All rights reserved.
//

#import "ChatWidget+Localizable.h"
#import "ChatManager.h"
#import <AgoraUIBaseViews/AgoraUIBaseViews-Swift.h>
#import <WHToast/WHToast.h>
#import "UIImage+ChatExt.h"
#import "ChatTopView.h"
#import "AnnouncementView.h"
#import "ChatView.h"
#import "CustomBadgeView.h"
#import "QAView.h"
#import "MembersView.h"
#import "QAUserListView.h"

static const NSString* kAvatarUrl = @"avatarUrl";
static const NSString* kNickname = @"nickName";
static const NSString* kChatRoomId = @"chatroomId";
static const NSString* kIsShowBadge = @"isShowBadge";

#define TOP_HEIGHT 34
#define MINIBUTTON_SIZE 40

@interface ChatWidget () <ChatManagerDelegate,
                          UITextFieldDelegate,
                          AgoraUIContainerDelegate,
                          ChatTopViewDelegate,AnnouncementViewDelegate,
                          ChatViewDelegate,UIScrollViewDelegate>
@property (nonatomic,strong) ChatManager* chatManager;
@property (nonatomic,strong) ChatTopView* chatTopView;
@property (nonatomic,strong) AnnouncementView* announcementView;
@property (nonatomic,strong) ChatView* chatView;
@property (nonatomic,strong) QAView* qaView;
@property (nonatomic,strong) MembersView* membersView;
@property (nonatomic,strong) AgoraBaseUIContainer* containView;
@property (nonatomic,strong) UITapGestureRecognizer *tap;
@property (nonatomic,strong) UIButton* miniButton;
@property (nonatomic,strong) CustomBadgeView* badgeView;
@property (nonatomic,strong) UIScrollView* scrollView;
@end

@implementation ChatWidget
- (instancetype)initWithWidgetId:(NSString *)widgetId
                      properties:(NSDictionary * _Nullable)properties {
    self = [super initWithWidgetId:widgetId
                        properties:properties];
    
    if (self) {
        self.containerView.delegate = self;
        [self initData:properties];
        [self initViews];
    }
    
    return self;
}

- (void)containerLayoutSubviews {
    [self layoutViews];
}

- (void)widgetDidReceiveMessage:(NSString *)message {
    if([message isEqualToString:@"min"]) {
        [self chatTopViewDidClickHide];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.chatManager logout];
}

#pragma mark - ChatWidget
- (void)initViews {
    
    self.containView = [[UIView alloc] initWithFrame:CGRectZero];
    self.containView.backgroundColor = [UIColor clearColor];
    self.containView.layer.borderWidth = 1;
    self.containView.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
    self.containView.layer.cornerRadius = 5;
    self.containView.layer.shadowColor = [UIColor colorWithRed:47/255.0 green:65/255.0 blue:146/255.0 alpha:0.15].CGColor;
    self.containView.layer.shadowOffset = CGSizeMake(0,1);
    self.containView.layer.shadowOpacity = 1;
    self.containView.layer.shadowRadius = 3;
    [self.containerView addSubview:self.containView];
    
    self.chatTopView = [[ChatTopView alloc] initWithFrame:CGRectZero];
    self.chatTopView.delegate = self;
    [self.containView addSubview:self.chatTopView];
    
    [self.containView addSubview:self.scrollView];
    
    self.announcementView = [[AnnouncementView alloc] initWithFrame:CGRectZero role:self.chatManager.userConfig.role];
    self.announcementView.delegate = self;
    
    self.chatView = [[ChatView alloc] initWithFrame:CGRectZero chatManager:self.chatManager];
    self.chatView.delegate = self;
    [self.scrollView addSubview:self.chatView];
    
    if(ROLE_IS_TEACHER(self.chatManager.user.role))
    {
        QAUserListView* qaUserListView = [[QAUserListView alloc] initWithFrame:CGRectZero];
        qaUserListView.chatManager = self.chatManager;
        qaUserListView.parantView = self;
        self.qaView = qaUserListView;
    }
    else
        self.qaView = [[QAView alloc] initWithFrame:CGRectZero];
    self.qaView.delegate = self;
    [self.scrollView addSubview:self.qaView];
    
    self.membersView = [[MembersView alloc] initWithFrame:CGRectZero];
    self.membersView.chatManager = self.chatManager;
    [self.scrollView addSubview:self.membersView];
    [self.scrollView addSubview:self.announcementView];
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(handleTapAction:)];
    [self.containView addGestureRecognizer:self.tap];
}

- (void)layoutViews {
    self.containView.frame = CGRectMake(0,
                                        0,
                                        self.containerView.bounds.size.width,
                                        self.containerView.bounds.size.height);
    self.chatTopView.frame = CGRectMake(0, 0, self.containView.bounds.size.width, TOP_HEIGHT);
    
    self.announcementView.frame = CGRectMake(self.containView.bounds.size.width * 3,0,self.containView.bounds.size.width ,self.containView.bounds.size.height - TOP_HEIGHT);
    
    self.chatView.frame = CGRectMake(0,0,self.containView.bounds.size.width,self.containView.bounds.size.height - TOP_HEIGHT);
    
    self.qaView.frame = CGRectMake(self.containView.bounds.size.width * 1,0,self.containView.bounds.size.width,self.containView.bounds.size.height - TOP_HEIGHT);
    
    self.membersView.frame = CGRectMake(self.containView.bounds.size.width *2,0,self.containView.bounds.size.width,self.containView.bounds.size.height - TOP_HEIGHT);
    
    self.miniButton.frame = CGRectMake(10, self.containerView.bounds.size.height - MINIBUTTON_SIZE - 10, MINIBUTTON_SIZE, MINIBUTTON_SIZE);
    
    self.badgeView.frame = CGRectMake(10 + MINIBUTTON_SIZE*4/5, self.containerView.bounds.size.height - MINIBUTTON_SIZE - 10, self.badgeView.badgeSize, self.badgeView.badgeSize);
    
    self.scrollView.frame = CGRectMake(0,TOP_HEIGHT,self.containView.bounds.size.width,self.containView.bounds.size.height - TOP_HEIGHT);
    
    self.scrollView.contentSize = CGSizeMake(self.containView.bounds.size.width * 4, self.containView.bounds.size.height - TOP_HEIGHT);
}

- (UIScrollView*)scrollView
{
    if(!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
    }
    return _scrollView;
}

- (void)handleTapAction:(UITapGestureRecognizer *)aTap
{
    if (aTap.state == UIGestureRecognizerStateEnded) {
        [self.containView endEditing:YES];
    }
}

- (void)recallMsg:(NSString*)msgId
{
}

- (void)initData:(NSDictionary *)properties {
    ChatUserConfig* user = [[ChatUserConfig alloc] init];
    
    user.avatarurl = properties[@"avatarurl"];
    user.username = [properties[@"userUuid"] lowercaseString];
    user.nickname = properties[@"userName"];
    user.roomUuid = properties[@"roomUuid"];
    NSNumber* role = properties[@"role"];
    user.role = role? role.intValue:2;
    //user.role = 3;
    
    kChatRoomId =  properties[@"chatRoomId"];
    
    NSString *appKey = properties[@"appkey"];
    NSString *password = properties[@"password"];
    
    ChatManager *manager = [[ChatManager alloc] initWithUserConfig:user
                                                            appKey:appKey
                                                          password:password
                                                        chatRoomId:kChatRoomId];
    NSDictionary* privateChatroom = [properties objectForKey:@"privateChatRoom"];
    if(privateChatroom)
    {
        NSNumber* enableQA = [privateChatroom objectForKey:@"enabled"];
        manager.enableQAChatroom = [enableQA boolValue];
        manager.qaChatRoomId = [privateChatroom objectForKey:@"chatRoomId"];
    }
    manager.delegate = self;
    self.chatManager = manager;
    self.chatView.chatManager = self.chatManager;
    
    [self.chatManager launch];
}

- (void)_showBadgeView:(BOOL)bShow
{
    NSDictionary *infoDict = @{kIsShowBadge:[NSNumber numberWithBool:bShow]};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict options:0 error:0];
    NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [self sendMessage:dataStr];
}

#pragma mark - ChatManagerDelegate
- (void)chatMessageDidReceive
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<EMMessage*>* array = [weakself.chatManager msgArray];
        [self.chatView updateMsgs:array];
        if(array.count > 0) {
            if([self.containerView isHidden]) {
                // 最小化了
                [self _showBadgeView:YES];
            }
            if(self.chatTopView.currentTab != 0) {
                // 显示红点
                self.chatTopView.isShowRedNotice = YES;
            }
        }
    });
    
}

- (void)qaMessageDidReceive
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<EMMessage*>* array = [weakself.chatManager qaArray];
        [self.qaView updateMsgs:array];
        if(array.count > 0) {
            if([self.containView isHidden]) {
                // 最小化了
                self.badgeView.hidden = NO;
            }
        }
    });
}

- (void)showQARedNotice:(BOOL)showQARedNotice
{
    self.chatTopView.isShowQARedNotice = showQARedNotice;
}

- (void)chatMessageDidSend:(EMMessage*)aInfo
{
    [self.chatView updateMsgs:@[aInfo]];
}

- (void)qaMessageDidSend:(EMMessage *)aMessage
{
    [self.qaView updateMsgs:@[aMessage]];
}

- (void)exceptionDidOccur:(NSString*)aErrorDescription
{
    [WHToast showErrorWithMessage:aErrorDescription duration:2 finishHandler:^{
            
    }];
}

- (void)mutedStateDidChanged
{
    if(!ROLE_IS_TEACHER(self.chatManager.user.role)) {
        self.chatView.chatBar.isAllMuted = self.chatManager.isAllMuted;
        self.chatView.chatBar.isMuted = self.chatManager.isMuted;
    }else{
        [self.chatView muteStateChange];
    }
    
}

- (void)muteMembersDidChannged
{
    [self.membersView updateMuteMembers:self.chatManager.muteMembers];
}

- (void)chatMessageDidRecall:(NSString*)aMessageId
{
    if(aMessageId.length > 0) {
        [self recallMsg:aMessageId];
    }
}

- (void)roomStateDidChanged:(ChatRoomState)aState
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (aState) {
            case ChatRoomStateLogin:
                
                break;
            case ChatRoomStateLoginFailed:
                [WHToast showErrorWithMessage:[ChatWidget LocalizedString:@"ChatLoginFaild"] duration:2 finishHandler:^{
                        
                }];
                break;
            case ChatRoomStateLogined:
                
                break;
            case ChatRoomStateJoining:
                
                break;
            case ChatRoomStateJoined:
                
                break;
            case ChatRoomStateJoinFail:
                [WHToast showErrorWithMessage:[ChatWidget LocalizedString:@"ChatJoinFaild"] duration:2 finishHandler:^{
                        
                }];
                break;
            default:
                break;
        }
    });
}

- (void)announcementDidChanged:(NSString *)aAnnouncement isFirst:(BOOL)aIsFirst
{
    self.chatView.announcement = aAnnouncement;
    self.announcementView.announcement = aAnnouncement;
    if(!aIsFirst) {
        if([self.containerView isHidden]) {
            // 最小化了
            [self _showBadgeView:YES];
        }
        if(self.chatTopView.currentTab != 1) {
            // 显示红点
            self.chatTopView.isShowAnnouncementRedNotice = YES;
        }
    }
}

- (BOOL)shouldShowBadge
{
    return !self.chatTopView.chatBadgeView.hidden || !self.chatTopView.announcementbadgeView.hidden;
}

- (void)membersDidChanged
{
    [self.membersView updateMembers:self.chatManager.members admins:self.chatManager.admins];
    self.chatTopView.membersCount = self.chatManager.members.count + self.chatManager.admins.count;
}

#pragma mark - ChatTopViewDelegate
- (void)chatTopViewDidSelectedChanged:(NSUInteger)nSelected
{
    self.scrollView.contentOffset = CGPointMake(self.containView.bounds.size.width * nSelected, 0);
//    switch (nSelected) {
//        case 0:
////            [self.announcementView removeFromSuperview];
////            [self.qaView removeFromSuperview];
////            [self.membersView removeFromSuperview];
////            [self.containView addSubview:self.chatView];
//            self.scrollView.contentOffset = CGPointMake(self.containView.bounds.size.width * 0, 0);
//            break;
//        case 1:
////            [self.announcementView removeFromSuperview];
////            [self.chatView removeFromSuperview];
////            [self.membersView removeFromSuperview];
////            [self.containView addSubview:self.qaView];
//            break;
//        case 2:
////            [self.announcementView removeFromSuperview];
////            [self.qaView removeFromSuperview];
////            [self.chatView removeFromSuperview];
////            [self.containView addSubview:self.membersView];
//            break;
//        case 3:
////            [self.chatView removeFromSuperview];
////            [self.qaView removeFromSuperview];
////            [self.membersView removeFromSuperview];
////            [self.containView addSubview:self.announcementView];
//            break;
//
//        default:
//            break;
//    }
}

- (void)chatTopViewDidClickHide
{
    BOOL isShowBadge = [self shouldShowBadge];
    NSDictionary *infoDict = @{@"isMinSize":@(1),kIsShowBadge:[NSNumber numberWithBool:isShowBadge]};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict options:0 error:0];
    NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [self sendMessage:dataStr];
}

- (void)showView
{
    self.containView.hidden = NO;
    if(self.chatTopView.currentTab == 0) {
        self.chatTopView.chatBadgeView.hidden = YES;
        [self.chatView scrollToBottomRow];
    }
    if(self.chatTopView.currentTab == 1) {
        self.chatTopView.announcementbadgeView.hidden = YES;
    }
    [self _showBadgeView:NO];
    if([[UIDevice currentDevice].model isEqualToString:@"iPad"]) {
        self.containerView.agora_width = 340;
    }else
        self.containerView.agora_width = 200;
    
    [self sendMessage:@"max"];
}

#pragma mark - ChatViewDelegate
- (void)chatViewDidClickAnnouncement
{
    self.chatTopView.currentTab = 3;
}

- (void)msgWillSend:(NSString *)aMsgText
{
    [self.chatManager sendTextMsg:aMsgText msgType:ChatMsgTypeCommon asker:nil];
}

- (void)imageDataWillSend:(NSData*)aImageData isQA:(BOOL)aIsQAMsg
{
    [self.chatManager sendImageMsgWithData:aImageData msgType:ChatMsgTypeCommon asker:nil];
}

- (void)msgWillSend:(NSString *)aMsgText type:(ChatMsgType)aMsgType
{
    [self.chatManager sendTextMsg:aMsgText msgType:ChatMsgTypeAsk asker:nil];
}

- (void)muteAllDidClick:(BOOL)aMuteAll
{
    [self.chatManager muteAll:aMuteAll];
}

#pragma mark - QAViewDelegate
- (void)msgWillSend:(NSString*)aMsgText type:(ChatMsgType)aMsgType asker:(NSString*)asker
{
    [self.chatManager sendTextMsg:aMsgText msgType:aMsgType asker:asker];
}
- (void)imageDataWillSend:(NSData*)aImageData type:(ChatMsgType)aMsgType asker:(NSString*)asker
{
    [self.chatManager sendImageMsgWithData:aImageData msgType:aMsgType asker:asker];
}
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

    NSLog(@"scrollViewDidEndDecelerating");

    CGPoint offset = self.scrollView.contentOffset;
    int width = self.containerView.bounds.size.width;
    if(width > 0)
        self.chatTopView.currentTab = offset.x/width;
}

#pragma mark - AnnouncementViewDelegate
- (void)PublishAnnouncement:(NSString*)aText
{
    [self.chatManager publishAnnouncement:aText];
}
@end
