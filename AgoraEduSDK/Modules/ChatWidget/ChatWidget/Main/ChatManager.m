//
//  ChatManager.m
//  AgoraEducation
//
//  Created by lixiaoming on 2021/5/12.
//  Copyright © 2021 Agora. All rights reserved.
//

#import "ChatManager.h"
#import "EMEmojiHelper.h"
#import "ChatWidget+Localizable.h"

const static NSString* kMsgType = @"msgtype";
const static NSString* kAvatarUrl = @"avatarUrl";
const static NSString* kNickName = @"nickName";
const static NSString* kRoomUuid = @"roomUuid";

static BOOL isSDKInited = NO;

@interface ChatManager ()<AgoraChatClientDelegate,AgoraChatManagerDelegate,AgoraChatroomManagerDelegate>
@property (nonatomic, copy) NSString* appkey;
@property (nonatomic, copy) NSString* password;
@property (nonatomic) BOOL isLogin;
@property (nonatomic,copy) NSMutableArray<AgoraChatMessage*>* dataArray;
@property (nonatomic,strong) NSLock* dataLock;
@property (nonatomic,strong) NSLock* askAndAnswerMsgLock;
@property (nonatomic,strong) AgoraChatroom* chatRoom;
@property (nonatomic,strong) NSMutableArray<AgoraChatMessage*>* askAndAnswerMsgs;
@property (nonatomic,strong) NSString* latestMsgId;
@end

@implementation ChatManager
- (instancetype)initWithUserConfig:(ChatUserConfig*)aUserConfig
                            appKey:(NSString *)appKey
                          password:(NSString *)password
                        chatRoomId:(NSString*)aChatRoomId;
{
    self = [super init];
    if(self) {
        self.appkey = appKey;
        self.password = password;
        self.user = aUserConfig;
        self.chatRoomId = aChatRoomId;
        self.isLogin = NO;
        self.hasNewMsgs = NO;
        [self initHyphenateSDK];
    }
    return self;
}

- (void)initHyphenateSDK
{
    AgoraChatOptions* option = [AgoraChatOptions optionsWithAppkey:self.appkey];
    option.enableConsoleLog = YES;
    option.isAutoLogin = NO;
    [[AgoraChatClient sharedClient] initializeSDKWithOptions:option];
    [[AgoraChatClient sharedClient] addDelegate:self delegateQueue:nil];
    
    [[AgoraChatClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    [[AgoraChatClient sharedClient].roomManager addDelegate:self delegateQueue:nil];
    isSDKInited = YES;
}

- (void)launch
{
    __weak typeof(self) weakself = self;
    if(isSDKInited && self.user.username.length > 0) {
        NSString* lowercaseName = [self.user.username lowercaseString];
        weakself.state = ChatRoomStateLogin;
        
        [[AgoraChatClient sharedClient] loginWithUsername:lowercaseName password:weakself.password completion:^(NSString *aUsername, AgoraChatError *aError) {
            if(!aError) {
                weakself.isLogin = YES;
            }else{
                if(aError.code == AgoraChatErrorUserNotFound) {
                    [[AgoraChatClient sharedClient] registerWithUsername:lowercaseName password:weakself.password completion:^(NSString *aUsername, AgoraChatError *aError) {
                        if(!aError) {
                            [[AgoraChatClient sharedClient] loginWithUsername:lowercaseName password:weakself.password completion:^(NSString *aUsername, AgoraChatError *aError) {
                                if(!aError) {
                                    weakself.isLogin = YES;
                                }
                            }];
                        }
                    }];
                }else{
                    weakself.state = ChatRoomStateLoginFailed;
                }
            }
        }];
    }
}

- (void)logout
{
    [[[AgoraChatClient sharedClient] roomManager] leaveChatroom:self.chatRoomId completion:nil];
    [[AgoraChatClient sharedClient] removeDelegate:self];
    [[AgoraChatClient sharedClient].chatManager removeDelegate:self];
    [[AgoraChatClient sharedClient].roomManager removeDelegate:self];
    [[AgoraChatClient sharedClient] logout:NO];
    self.latestMsgId = @"";
}

- (void)setIsLogin:(BOOL)isLogin
{
    _isLogin = isLogin;
    if(_isLogin) {
        if(self.chatRoomId.length > 0) {
            __weak typeof(self) weakself = self;
            weakself.state = ChatRoomStateJoining;
            [[AgoraChatClient sharedClient].roomManager joinChatroom:self.chatRoomId completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
                if(!aError) {
                    self.chatRoom = aChatroom;
                    weakself.state = ChatRoomStateJoined;
                    [weakself fetchChatroomData];
                }else{
                    weakself.state = ChatRoomStateJoinFail;
                }
            }];
        }
        AgoraChatUserInfo* userInfo = [[AgoraChatUserInfo alloc] init];
        NSDictionary* extDic = @{@"role":@2};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extDic options:0 error:nil];
        NSString* str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        userInfo.ext = str;
        if(self.user.avatarurl.length > 0)
            userInfo.avatarUrl = self.user.avatarurl;
        if(self.user.nickname.length > 0)
            userInfo.nickName = self.user.nickname ;
        
        [[[AgoraChatClient sharedClient] userInfoManager] updateOwnUserInfo:userInfo completion:^(AgoraChatUserInfo *aUserInfo, AgoraChatError *aError) {
                        
        }];
    }
}

- (void)fetchChatroomData
{
    __weak typeof(self) weakself = self;
    // 获取聊天室详情
    [[[AgoraChatClient sharedClient] roomManager] getChatroomSpecificationFromServerWithId:self.chatRoomId completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
        if(!aError)
        {
            weakself.chatRoom = aChatroom;
            weakself.isAllMuted = aChatroom.isMuteAllMembers;
            if(weakself.isAllMuted)
                [weakself.delegate mutedStateDidChanged];
        }
    }];
    [[[AgoraChatClient sharedClient] chatManager] asyncFetchHistoryMessagesFromServer:self.chatRoomId conversationType:AgoraChatConversationTypeGroupChat startMessageId:@"" pageSize:50 completion:^(AgoraChatCursorResult *aResult, AgoraChatError *aError) {
            if(aResult.list.count > 0){
                if(weakself.latestMsgId.length > 0)
                {
                    NSArray* arr = [[aResult.list reverseObjectEnumerator] allObjects];
                    NSMutableArray* msgToAdd = [NSMutableArray array];
                    for (AgoraChatMessage* msg in arr) {
                        if([msg.messageId isEqualToString:weakself.latestMsgId]) {
                            if(weakself.dataArray.count > 0){
                                [weakself.delegate chatMessageDidReceive];
                            }
                            return;
                        }else{
                            [weakself.dataArray insertObject:msg atIndex:0];
                        }
                    }
                }else{
                    [weakself.dataArray addObjectsFromArray:aResult.list];
                    AgoraChatMessage* lastMsg = [aResult.list lastObject];
                    if(lastMsg)
                        weakself.latestMsgId = lastMsg.messageId;
                    [weakself.delegate chatMessageDidReceive];
                }
            }
    }];
    
    // 获取是否被禁言
    [[[AgoraChatClient sharedClient] roomManager] isMemberInWhiteListFromServerWithChatroomId:self.chatRoomId completion:^(BOOL inWhiteList, AgoraChatError *aError) {
        if(!aError) {
            weakself.isMuted = inWhiteList;
            if(weakself.isMuted)
                [weakself.delegate mutedStateDidChanged];
        }
    }];
    // 获取公告
    [[[AgoraChatClient sharedClient] roomManager] getChatroomAnnouncementWithId:self.chatRoomId completion:^(NSString *aAnnouncement, AgoraChatError *aError) {
        if(!aError)
        {
            [weakself.delegate announcementDidChanged:aAnnouncement isFirst:YES];
        }
    }];
}

- (NSMutableArray<AgoraChatMessage*>*)dataArray
{
    if(!_dataArray) {
        _dataArray = [NSMutableArray<AgoraChatMessage*> array];
    }
    return _dataArray;
}

- (NSArray<AgoraChatMessage*> *)msgArray
{
    [self.dataLock lock];
    NSArray<AgoraChatMessage*> * array = [self.dataArray copy];
    [self.dataArray removeAllObjects];
    [self.dataLock unlock];
    return array;
}

- (NSMutableArray<AgoraChatMessage*>*)askAndAnswerMsgs
{
    if(!_askAndAnswerMsgs) {
        _askAndAnswerMsgs = [NSMutableArray<AgoraChatMessage*> array];
    }
    return _askAndAnswerMsgs;
}

- (void)setState:(ChatRoomState)state
{
    _state = state;
    if(self.delegate) {
        [self.delegate roomStateDidChanged:state];
    }
}

- (NSLock*)dataLock
{
    if(!_dataLock) {
        _dataLock = [[NSLock alloc] init];
    }
    return _dataLock;
}

- (NSLock*)askAndAnswerMsgLock
{
    if(!_askAndAnswerMsgLock) {
        _askAndAnswerMsgLock = [[NSLock alloc] init];
    }
    return _askAndAnswerMsgLock;
}

- (void)sendCommonTextMsg:(NSString*)aText
{
    [self sendTextMsg:aText msgType:ChatMsgTypeCommon];
}
- (void)sendAskMsgText:(NSString*)aText
{
    [self sendTextMsg:aText msgType:ChatMsgTypeAsk];
}
- (void)sendTextMsg:(NSString*)aText msgType:(ChatMsgType)aType
{
    if(aText.length > 0  && self.isLogin) {
        if(self.user.avatarurl.length <= 0) {
            self.user.avatarurl = @"https://download-sdk.oss-cn-beijing.aliyuncs.com/downloads/IMDemo/avatar/Image1.png";
        }
        AgoraChatTextMessageBody* textBody = [[AgoraChatTextMessageBody alloc] initWithText:aText];
        NSMutableDictionary* ext = [@{kMsgType:[NSNumber numberWithInteger: aType],
                                      @"role": [NSNumber numberWithInteger:self.user.role],
                                      kAvatarUrl: self.user.avatarurl} mutableCopy];
        if(self.user.nickname.length > 0 ){
            [ext setObject:self.user.nickname forKey:kNickName];
        }
        if(self.user.avatarurl.length > 0 ){
            [ext setObject:self.user.avatarurl forKey:kAvatarUrl];
        }
        if(self.user.roomUuid.length > 0) {
            [ext setObject:self.user.roomUuid forKey:kRoomUuid];
        }
        
        AgoraChatMessage* msg = [[AgoraChatMessage alloc] initWithConversationID:self.chatRoomId from:self.user.username to:self.chatRoomId body:textBody ext:ext];
        msg.chatType = AgoraChatTypeChatRoom;
        __weak typeof(self) weakself = self;
        [[AgoraChatClient sharedClient].chatManager sendMessage:msg progress:^(int progress) {
                    
                } completion:^(AgoraChatMessage *message, AgoraChatError *error) {
                    if(!error) {
                        if(aType == ChatMsgTypeCommon) {
                            if([weakself.delegate respondsToSelector:@selector(chatMessageDidSend:)]){
                                [weakself.delegate chatMessageDidSend:message];
                            }
                        }
                        if(aType == ChatMsgTypeAsk) {
                            [weakself.askAndAnswerMsgLock lock];
                            [weakself.askAndAnswerMsgs addObject:message];
                            [weakself.askAndAnswerMsgLock unlock];
                        }
                    }else{
                        if(error.code == AgoraChatErrorMessageIncludeIllegalContent)
                            [weakself.delegate exceptionDidOccur:[ChatWidget LocalizedString:@"ChatSendFaildBySensitive"]];
                        else {
                            if(error.code == AgoraChatErrorUserMuted) {
                                [weakself.delegate exceptionDidOccur:[ChatWidget LocalizedString:@"ChatSendFaildByMute"]];
                                if(!weakself.isAllMuted) {
                                    if(!weakself.isMuted) {
                                        weakself.isMuted = YES;
                                        [weakself.delegate mutedStateDidChanged];
                                    }
                                }
                            }else{
                                [weakself.delegate exceptionDidOccur:error.errorDescription];
                            }
                        }
                        
                    }
                }];
    }
}

- (ChatUserConfig*)userConfig
{
    return self.user;
}

// 更新头像
- (void)updateAvatar:(NSString*)avatarUrl
{
    self.user.avatarurl = avatarUrl ;
    if(avatarUrl.length > 0) {
        [[[AgoraChatClient sharedClient] userInfoManager] updateOwnUserInfo:avatarUrl withType:AgoraChatUserInfoTypeAvatarURL completion:nil];
    }
}
// 更新昵称
- (void)updateNickName:(NSString*)nickName
{
    self.user.nickname = nickName;
    if(nickName.length > 0){
        [[[AgoraChatClient sharedClient] userInfoManager] updateOwnUserInfo:nickName withType:AgoraChatUserInfoTypeNickName completion:nil];
    }
}

#pragma mark - EMClientDelegate
- (void)connectionStateDidChange:(AgoraChatConnectionState)aConnectionState
{
    NSLog(@"connectionStateDidChange:%d",aConnectionState);
    if(aConnectionState == AgoraChatConnectionConnected) {
        __weak typeof(self) weakself = self;
        [[AgoraChatClient sharedClient].roomManager joinChatroom:self.chatRoomId completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
            if(!aError || aError.code == AgoraChatErrorGroupAlreadyJoined) {
                [weakself fetchChatroomData];
            }else{
                weakself.state = ChatRoomStateJoinFail;
            }
        }];
    }
}

- (void)userAccountDidLoginFromOtherDevice
{
    [self.delegate exceptionDidOccur:[ChatWidget LocalizedString:@"ChatLoginOnOtherDevice"]];
}

- (void)userAccountDidForcedToLogout:(AgoraChatError *)aError
{
    [self.delegate exceptionDidOccur:[ChatWidget LocalizedString:@"ChatLogoutForced"]];
}

#pragma mark - EMChatManagerDelegate
- (void)messagesDidReceive:(NSArray *)aMessages
{
    BOOL aInsertCommonMsg = NO;
    for (AgoraChatMessage* msg in aMessages) {
        // 判断聊天室消息
        if(msg.chatType == AgoraChatTypeChatRoom && [msg.to isEqualToString:self.chatRoomId]) {
            // 文本消息
            if(msg.body.type == AgoraChatMessageBodyTypeText) {
                NSDictionary* ext = msg.ext;
                NSNumber* msgType = [ext objectForKey:kMsgType];
                AgoraChatTextMessageBody* textBody = (AgoraChatTextMessageBody*)msg.body;
                // 普通消息
                //if(msgType.integerValue == ChatMsgTypeCommon) {
                    if([textBody.text length] > 0)
                    {
                        NSString* avatarUrl = [ext objectForKey:kAvatarUrl];
                        [self.dataLock lock];
                        [self.dataArray addObject:msg];
                        self.latestMsgId = msg.messageId;
                        [self.dataLock unlock];
                        aInsertCommonMsg = YES;
                    }
               // }
//                // 问答消息
//                if(msgType.integerValue == ChatMsgAnswer) {
//                    NSString* asker = [ext objectForKey:@"asker"];
//                    if([asker isEqualToString:self.user.username]) {
//                        [self.askAndAnswerMsgLock lock];
//                        [self.askAndAnswerMsgs addObject:msg];
//                        [self.askAndAnswerMsgLock unlock];
//                    }
//                }
            }
        }
    }
    if(aInsertCommonMsg) {
        // 这里需要读取消息展示
        if([self.delegate respondsToSelector:@selector(chatMessageDidReceive)]) {
            [self.delegate chatMessageDidReceive];
        }
    }
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages
{
    for(AgoraChatMessage* msg in aCmdMessages) {
        AgoraChatCmdMessageBody* body = (AgoraChatCmdMessageBody*)msg.body;
        if([body.action isEqualToString:@"DEL"]) {
            NSDictionary* ext = msg.ext;
            id tmp = [ext objectForKey:@"msgId"];
            NSString* msgIdToDel = @"";
            if([tmp isKindOfClass:[NSString class]]) {
                NSString* msgId = (NSString*)tmp;
                msgIdToDel = (NSString*)tmp;
            }
            if([tmp isKindOfClass:[NSNumber class]]) {
                NSNumber* num = (NSNumber*)tmp;
                msgIdToDel = [NSString stringWithFormat:@"%ld",num.unsignedIntValue];
            }
            if(msgIdToDel.length > 0) {
                if([self.delegate respondsToSelector:@selector(chatMessageDidRecallchatMessageDidRecall:)]) {
                    [self.delegate chatMessageDidRecall:msgIdToDel];
                }
            }
        }
    }
    [self.dataLock lock];
    [self.dataArray addObjectsFromArray:aCmdMessages];
    AgoraChatMessage* lastMsg = [aCmdMessages lastObject];
    if(lastMsg)
        self.latestMsgId = lastMsg.messageId;
    [self.dataLock unlock];
    self.hasNewMsgs = YES;
    if([self.delegate respondsToSelector:@selector(chatMessageDidReceive)]) {
        [self.delegate chatMessageDidReceive];
    }
}

- (void)messagesDidRecall:(NSArray *)aMessages
{
    for (AgoraChatMessage* msg in aMessages) {
        // 判断聊天室消息
        if(msg.chatType == AgoraChatTypeChatRoom && [msg.to isEqualToString:self.chatRoomId]) {
            // 文本消息
            if(msg.body.type == AgoraChatMessageBodyTypeText) {
                NSDictionary* ext = msg.ext;
                NSNumber* msgType = [ext objectForKey:kMsgType];
                // 普通消息
                //if(msgType.integerValue == ChatMsgTypeCommon) {
                AgoraChatTextMessageBody* textBody = (AgoraChatTextMessageBody*)msg.body;
                    if([textBody.text length] > 0)
                    {
                        if([self.delegate respondsToSelector:@selector(chatMessageDidRecallchatMessageDidRecall:)]) {
                            [self.delegate chatMessageDidRecall:msg.messageId];
                        }
                    }
                //}
            }
        }
    }
}

- (void)messageStatusDidChange:(AgoraChatMessage *)aMessage
                         error:(AgoraChatError *)aError
{
   
}

#pragma mark - AgoraChatroomManagerDelegate
- (void)userDidJoinChatroom:(AgoraChatroom *)aChatroom
                       user:(NSString *)aUsername
{
    
}

- (void)userDidLeaveChatroom:(AgoraChatroom *)aChatroom
                        user:(NSString *)aUsername
{
    
}

- (void)didDismissFromChatroom:(AgoraChatroom *)aChatroom
                        reason:(AgoraChatroomBeKickedReason)aReason
{
}

- (void)chatroomMuteListDidUpdate:(AgoraChatroom *)aChatroom
                addedMutedMembers:(NSArray *)aMutes
                       muteExpire:(NSInteger)aMuteExpire
{
    
}

- (void)chatroomMuteListDidUpdate:(AgoraChatroom *)aChatroom
              removedMutedMembers:(NSArray *)aMutes
{
    
}

- (void)chatroomWhiteListDidUpdate:(AgoraChatroom *)aChatroom
             addedWhiteListMembers:(NSArray *)aMembers
{
    if([aChatroom.chatroomId isEqualToString:self.chatRoomId]) {
        if(aMembers.count > 0 && [aMembers containsObject:self.user.username]) {
            self.isMuted = YES;
            if(self.delegate)
                [self.delegate mutedStateDidChanged];
        }
    }
}

- (void)chatroomWhiteListDidUpdate:(AgoraChatroom *)aChatroom
           removedWhiteListMembers:(NSArray *)aMembers
{
    if([aChatroom.chatroomId isEqualToString:self.chatRoomId]){
        if(aMembers.count > 0 && [aMembers containsObject:self.user.username]) {
            self.isMuted = NO;
            if(self.delegate)
                [self.delegate mutedStateDidChanged];
        }
    }
}

- (void)chatroomAllMemberMuteChanged:(AgoraChatroom *)aChatroom
                    isAllMemberMuted:(BOOL)aMuted
{
    if([aChatroom.chatroomId isEqualToString:self.chatRoomId]) {
        self.isAllMuted = aMuted;
        [self.delegate mutedStateDidChanged];
    }
    
}

- (void)chatroomAnnouncementDidUpdate:(AgoraChatroom *)aChatroom
                         announcement:(NSString *)aAnnouncement
{
    if([aChatroom.chatroomId isEqualToString:self.chatRoomId]) {
        [self.delegate announcementDidChanged:aAnnouncement isFirst:NO];
    }
}

- (void)_parseAnnouncement:(NSString*)aAnnouncement
{
    if(aAnnouncement.length > 0) {
        NSString* strAllMute = [aAnnouncement substringToIndex:1];
        self.isAllMuted = [strAllMute boolValue];
        [self.delegate mutedStateDidChanged];
    }
}
@end
