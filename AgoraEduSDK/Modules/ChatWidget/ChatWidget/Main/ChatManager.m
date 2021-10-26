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
const static NSString* kAsker = @"asker";

static BOOL isSDKInited = NO;

@interface ChatManager ()<AgoraChatClientDelegate,AgoraChatManagerDelegate,AgoraChatroomManagerDelegate>
@property (nonatomic, copy) NSString* appkey;
@property (nonatomic, copy) NSString* password;
@property (nonatomic) BOOL isLogin;
@property (nonatomic,copy) NSMutableArray<AgoraChatMessage*>* dataArray;
@property (nonatomic,strong) NSLock* dataLock;
@property (nonatomic,strong) NSLock* askAndAnswerMsgLock;
@property (nonatomic,strong) AgoraChatroom* chatRoom;
@property (nonatomic,strong) AgoraChatroom* qaChatRoom;
@property (nonatomic,strong) NSMutableArray<AgoraChatMessage*>* askAndAnswerMsgs;
@property (nonatomic,strong) NSString* latestMsgId;
@property (nonatomic,strong) NSString* latestQAMsgId;
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
    option.usingHttpsOnly = YES;
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
    self.latestQAMsgId = @"";
}

- (NSMutableArray*)members
{
    if(!_members) {
        _members = [NSMutableArray array];
    }
    return _members;
}

- (NSMutableArray*)admins
{
    if(!_admins) {
        _admins = [NSMutableArray array];
    }
    return _admins;
}

- (NSMutableArray*)muteMembers
{
    if(!_muteMembers) {
        _muteMembers = [NSMutableArray array];
    }
    return _muteMembers;
}

- (void)setIsLogin:(BOOL)isLogin
{
    _isLogin = isLogin;
    if(_isLogin) {
        AgoraChatUserInfo* userInfo = [[AgoraChatUserInfo alloc] init];
        NSDictionary* extDic = @{@"role":[NSNumber numberWithInteger:self.user.role]};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extDic options:0 error:nil];
        NSString* str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        userInfo.ext = str;
        if(self.user.avatarurl.length > 0)
        {
            //NSString* url = [self.user.avatarurl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"&"].invertedSet];
            userInfo.avatarUrl = self.user.avatarurl;
        }
        if(self.user.nickname.length > 0)
            userInfo.nickName = self.user.nickname ;
        
        [[[AgoraChatClient sharedClient] userInfoManager] updateOwnUserInfo:userInfo completion:^(AgoraChatUserInfo *aUserInfo, AgoraChatError *aError) {
            
        }];
        
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
        if(self.enableQAChatroom && self.qaChatRoomId.length > 0) {
            __weak typeof(self) weakself = self;
            weakself.state = ChatRoomStateJoining;
            [[AgoraChatClient sharedClient].roomManager joinChatroom:self.qaChatRoomId completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
                if(!aError) {
                    self.qaChatRoom = aChatroom;
                    [weakself fetchQAMessage];
                }else{
                    //weakself.state = ChatRoomStateJoinFail;
                }
            }];
        }
    }
}

- (void)fetchQAMessage
{
    AgoraChatCursorResult* result =  [[[AgoraChatClient sharedClient] chatManager] fetchHistoryMessagesFromServer:self.qaChatRoomId conversationType:AgoraChatConversationTypeGroupChat startMessageId:@"" pageSize:50 error:nil];
    if(result.list.count > 0){
        if(self.latestQAMsgId.length > 0)
        {
            NSArray* arr = [[result.list reverseObjectEnumerator] allObjects];
            NSMutableArray* msgToAdd = [NSMutableArray array];
            for (AgoraChatMessage* msg in arr) {
                if([msg.messageId isEqualToString:self.latestQAMsgId]) {
                    if(self.askAndAnswerMsgs.count > 0){
                        [self.delegate qaMessageDidReceive];
                    }
                    return;
                }else{
                    NSDictionary* ext  = msg.ext;
                    NSNumber* msgType = [ext objectForKey:kMsgType];
                    NSString* asker = [ext objectForKey:kAsker];
                    if(ROLE_IS_TEACHER(self.userConfig.role) || (msgType && msgType.integerValue > 0 && [asker isEqualToString:[AgoraChatClient sharedClient].currentUsername])) {
                        [self.askAndAnswerMsgs insertObject:msg atIndex:0];
                    }
                }
            }
        }else{
            for(AgoraChatMessage* msg in result.list) {
                NSDictionary* ext  = msg.ext;
                NSNumber* msgType = [ext objectForKey:kMsgType];
                NSString* asker = [ext objectForKey:kAsker];
                if(ROLE_IS_TEACHER(self.userConfig.role) ||  (msgType && msgType.integerValue > 0 && [asker isEqualToString:[AgoraChatClient sharedClient].currentUsername])) {
                    [self.askAndAnswerMsgs addObject:msg];
                }
            }
            AgoraChatMessage* lastMsg = [result.list lastObject];
            if(lastMsg)
                self.latestQAMsgId = lastMsg.messageId;
            if(self.askAndAnswerMsgs.count > 0)
                [self.delegate qaMessageDidReceive];
        }
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
            weakself.admins  = aChatroom.adminList;
            weakself.members = aChatroom.memberList;
            for(NSString* admin in weakself.admins) {
                [weakself.members removeObject:admin];
            }
            
            if(weakself.isAllMuted)
                [weakself.delegate mutedStateDidChanged];
            if(![weakself.members containsObject:[AgoraChatClient sharedClient].currentUsername] && !ROLE_IS_TEACHER(weakself.user.role))
                [weakself.members addObject:[AgoraChatClient sharedClient].currentUsername];
            [weakself.delegate membersDidChanged];
        }
    }];
    AgoraChatCursorResult* result =  [[[AgoraChatClient sharedClient] chatManager] fetchHistoryMessagesFromServer:self.chatRoomId conversationType:AgoraChatConversationTypeGroupChat startMessageId:@"" pageSize:50 error:nil];
    if(result.list.count > 0){
        if(self.latestMsgId.length > 0)
        {
            NSArray* arr = [[result.list reverseObjectEnumerator] allObjects];
            NSMutableArray* msgToAdd = [NSMutableArray array];
            for (AgoraChatMessage* msg in arr) {
                if([msg.messageId isEqualToString:self.latestMsgId]) {
                    if(self.dataArray.count > 0){
                        [self.delegate chatMessageDidReceive];
                    }
                }else{
                    [self.dataArray insertObject:msg atIndex:0];
                }
            }
        }else{
            for(AgoraChatMessage* msg in result.list) {
                [self.dataArray addObject:msg];
            }
            AgoraChatMessage* lastMsg = [result.list lastObject];
            if(lastMsg)
                self.latestMsgId = lastMsg.messageId;
            if(self.dataArray.count > 0)
                [weakself.delegate chatMessageDidReceive];
        }
    }
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
    
    if(ROLE_IS_TEACHER(self.user.role)) {
        [[[AgoraChatClient sharedClient] roomManager] getChatroomWhiteListFromServerWithId:self.chatRoomId completion:^(NSArray *aList, AgoraChatError *aError) {
            if(!aError) {
                weakself.muteMembers = [aList mutableCopy];
                [weakself.muteMembers removeObjectsInArray:weakself.admins];
                if(weakself.delegate)
                    [weakself.delegate muteMembersDidChannged];
            }
        }];
    }
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

- (NSArray<AgoraChatMessage*> *)qaArray
{
    [self.askAndAnswerMsgLock lock];
    NSArray<AgoraChatMessage*> * array = [self.askAndAnswerMsgs copy];
    [self.askAndAnswerMsgs removeAllObjects];
    [self.askAndAnswerMsgLock unlock];
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

- (void)sendTextMsg:(NSString*)aText msgType:(ChatMsgType)aType asker:(NSString*)aAsker
{
    if(aText.length > 0  && self.isLogin) {
        if(self.user.avatarurl.length <= 0) {
            self.user.avatarurl = @"https://download-sdk.oss-cn-beijing.aliyuncs.com/downloads/IMDemo/avatar/Image1.png";
        }
        AgoraChatTextMessageBody* textBody = [[AgoraChatTextMessageBody alloc] initWithText:aText];
        NSMutableDictionary* ext = [@{kMsgType:[NSNumber numberWithInteger: aType],
                                      @"role": [NSNumber numberWithInteger:self.user.role]} mutableCopy];
        if(self.user.nickname.length > 0 ){
            [ext setObject:self.user.nickname forKey:kNickName];
        }
        if(self.user.avatarurl.length > 0 ){
            [ext setObject:self.user.avatarurl forKey:kAvatarUrl];
        }
        if(self.user.roomUuid.length > 0) {
            [ext setObject:self.user.roomUuid forKey:kRoomUuid];
        }
        if(aType != ChatMsgTypeCommon) {
            if(aAsker.length > 0) {
                [ext setObject:aAsker forKey:kAsker];
            }else
                [ext setObject:[AgoraChatClient sharedClient].currentUsername forKey:kAsker];
        }
        NSString* convId = aType == ChatMsgTypeCommon ?  self.chatRoomId : self.qaChatRoomId;
        AgoraChatMessage* msg = [[AgoraChatMessage alloc] initWithConversationID:convId from:[AgoraChatClient sharedClient].currentUsername to:convId body:textBody ext:ext];
        msg.chatType = AgoraChatTypeChatRoom;
        __weak typeof(self) weakself = self;
        [[AgoraChatClient sharedClient].chatManager sendMessage:msg progress:^(int progress) {
                    
                } completion:^(AgoraChatMessage *message, AgoraChatError *error) {
                    if(!error) {
                        if(aType == ChatMsgTypeCommon) {
                            if([weakself.delegate respondsToSelector:@selector(chatMessageDidSend:)]){
                                [weakself.delegate chatMessageDidSend:message];
                            }
                        }else {
                            [weakself.delegate qaMessageDidSend:msg];
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

- (void)sendImageMsgWithData:aImageData msgType:(ChatMsgType)aType asker:(NSString *)aAsker
{
    AgoraChatImageMessageBody *body = [[AgoraChatImageMessageBody alloc] initWithData:aImageData displayName:@"image"];
    NSString *from = [[AgoraChatClient sharedClient] currentUsername];
    NSString *to = self.chatRoomId;
    NSMutableDictionary* ext = [@{kMsgType:[NSNumber numberWithInteger: aType],
                                  @"role": [NSNumber numberWithInteger:self.user.role]} mutableCopy];
    if(self.user.nickname.length > 0 ){
        [ext setObject:self.user.nickname forKey:kNickName];
    }
    if(self.user.avatarurl.length > 0 ){
        [ext setObject:self.user.avatarurl forKey:kAvatarUrl];
    }
    if(self.user.roomUuid.length > 0) {
        [ext setObject:self.user.roomUuid forKey:kRoomUuid];
    }
    if(aType != ChatMsgTypeCommon) {
        if(aAsker.length > 0) {
            [ext setObject:aAsker forKey:kAsker];
        }else
            [ext setObject:[AgoraChatClient sharedClient].currentUsername forKey:kAsker];
    }
    
    AgoraChatMessage *message = [[AgoraChatMessage alloc] initWithConversationID:to from:from to:to body:body ext:ext];
    
    message.chatType = AgoraChatTypeChatRoom;
    message.status = AgoraChatMessageStatusDelivering;
    
    [[AgoraChatClient sharedClient].chatManager sendMessage:message progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if(!error) {
            if(aType != ChatMsgTypeCommon)
                [self.delegate qaMessageDidSend:message];
            else
                [self.delegate chatMessageDidSend:message];
        }else{
            [self.delegate exceptionDidOccur:error.errorDescription];
        }
    }];
}

- (void)muteAll:(BOOL)aMuteAll
{
    __weak typeof(self) weakself = self;
    if(aMuteAll) {
        [[[AgoraChatClient sharedClient] roomManager] muteAllMembersFromChatroom:self.chatRoomId completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
            if(!aError) {
                weakself.isAllMuted = YES;
                if(weakself.delegate)
                    [weakself.delegate mutedStateDidChanged];
                [weakself sendMuteAllMsg:YES];
            }
        }];
    }else{
        [[[AgoraChatClient sharedClient] roomManager] unmuteAllMembersFromChatroom:self.chatRoomId completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
            if(!aError) {
                weakself.isAllMuted = NO;
                if(weakself.delegate)
                    [weakself.delegate mutedStateDidChanged];
                [weakself sendMuteAllMsg:NO];
            }
        }];
    }
}

- (void)muteMember:(NSString*)aUserId mute:(BOOL)aMute
{
    if(aUserId.length <= 0)
        return;
    __weak typeof(self) weakself = self;
    if(aMute) {
        [[[AgoraChatClient sharedClient] roomManager] addWhiteListMembers:@[aUserId] fromChatroom:self.chatRoomId completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
            [weakself.muteMembers addObject:aUserId];
            if(weakself.delegate)
                [weakself.delegate muteMembersDidChannged];
        }];
    }else{
        [[[AgoraChatClient sharedClient] roomManager] removeWhiteListMembers:@[aUserId] fromChatroom:self.chatRoomId completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
            [weakself.muteMembers removeObject:aUserId];
            if(weakself.delegate)
                [weakself.delegate muteMembersDidChannged];
        }];
    }
}

- (void)deleteMessage:(NSString*)aMsgId
{
    if(aMsgId.length <= 0)
        return;
    AgoraChatCmdMessageBody* cmdBody = [[AgoraChatCmdMessageBody alloc] initWithAction:@"DEL"];
    NSMutableDictionary*ext = [@{kRoomUuid:self.user.roomUuid,kMsgType:@1,@"msgId":aMsgId} mutableCopy];
    if(self.user.nickname.length > 0) {
        [ext setObject:self.user.nickname forKey:kNickName];
    }
    if(self.user.avatarurl.length > 0) {
        [ext setObject:self.user.avatarurl forKey:kAvatarUrl];
    }
    
    AgoraChatMessage * msg = [[AgoraChatMessage alloc] initWithConversationID:self.chatRoomId from:self.user.username to:self.chatRoomId body:cmdBody ext:ext];
    msg.chatType = AgoraChatTypeChatRoom;
    __weak typeof(self) weakself = self;
    [[[AgoraChatClient sharedClient] chatManager] sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if(!error) {
            if(weakself.delegate) {
                [weakself.delegate chatMessageDidSend:msg];
            }
        }
        
    }];
}

- (void)sendMuteAllMsg:(BOOL)aMuteAll
{
    NSString* action = aMuteAll?@"setAllMute":@"removeAllMute";
    AgoraChatCmdMessageBody* cmdBody = [[AgoraChatCmdMessageBody alloc] initWithAction:action];
    NSMutableDictionary*ext = [@{kRoomUuid:self.user.roomUuid,kMsgType:@1} mutableCopy];
    if(self.user.nickname.length > 0) {
        [ext setObject:self.user.nickname forKey:kNickName];
    }
    if(self.user.avatarurl.length > 0) {
        [ext setObject:self.user.avatarurl forKey:kAvatarUrl];
    }
    AgoraChatMessage * msg = [[AgoraChatMessage alloc] initWithConversationID:self.chatRoomId from:self.user.username to:self.chatRoomId body:cmdBody ext:ext];
    msg.chatType = AgoraChatTypeChatRoom;
    __weak typeof(self) weakself = self;
    [[[AgoraChatClient sharedClient] chatManager] sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if(!error) {
            if(weakself.delegate) {
                [weakself.delegate chatMessageDidSend:msg];
            }
        }
        
    }];
}

- (void)publishAnnouncement:(NSString*)aAnnouncement
{
    __weak typeof(self) weakself = self;
    [[[AgoraChatClient sharedClient] roomManager] updateChatroomAnnouncementWithId:self.chatRoomId announcement:aAnnouncement completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
            if(!aError) {
                weakself.chatroomAnnouncement = aAnnouncement;
                if(weakself.delegate) {
                    [weakself.delegate announcementDidChanged:aAnnouncement isFirst:NO];
                }
            }
    }];
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

#pragma mark - AgoraChatClientDelegate
- (void)connectionStateDidChange:(AgoraChatConnectionState)aConnectionState
{
    NSLog(@"connectionStateDidChange:%d",aConnectionState);
    if(aConnectionState == AgoraChatConnectionConnected) {
        __weak typeof(self) weakself = self;
        [[AgoraChatClient sharedClient].roomManager joinChatroom:self.chatRoomId completion:^(AgoraChatroom *aChatroom, AgoraChatError *aError) {
            if(!aError || aError.code == AgoraChatErrorGroupAlreadyJoined) {
                [weakself fetchChatroomData];
                if(weakself.enableQAChatroom)
                    [weakself fetchQAMessage];
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
    for (AgoraChatMessage* msg in aMessages) {
        // 文本消息,图片消息
        if(msg.body.type == AgoraChatMessageBodyTypeText || msg.body.type == AgoraChatMessageBodyTypeImage) {
            if(msg.chatType == AgoraChatTypeChatRoom && [msg.to isEqualToString:self.chatRoomId]) {
                [self.dataLock lock];
                [self.dataArray addObject:msg];
                self.latestMsgId = msg.messageId;
                [self.dataLock unlock];
            }
            if(msg.chatType == AgoraChatTypeChatRoom && [msg.to isEqualToString:self.qaChatRoomId]) {
                [self.askAndAnswerMsgLock lock];
                [self.askAndAnswerMsgs addObject:msg];
                self.latestQAMsgId = msg.messageId;
                [self.askAndAnswerMsgLock unlock];
            }
        }
    }
    if(self.dataArray.count > 0) {
        // 这里需要读取消息展示
        if([self.delegate respondsToSelector:@selector(chatMessageDidReceive)]) {
            [self.delegate chatMessageDidReceive];
        }
    }
    if(self.askAndAnswerMsgs.count > 0) {
        if([self.delegate respondsToSelector:@selector(qaMessageDidReceive)]) {
            [self.delegate qaMessageDidReceive];
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
    if([aChatroom.chatroomId isEqualToString:self.chatRoomId] && ![self.members containsObject:aUsername] && ![self.admins containsObject:aUsername]) {
        [self.members addObject:aUsername];
        [self.members removeObjectsInArray:self.admins];
        if(self.delegate && [self.delegate respondsToSelector:@selector(membersDidChanged)])
            [self.delegate membersDidChanged];
    }
}

- (void)userDidLeaveChatroom:(AgoraChatroom *)aChatroom
                        user:(NSString *)aUsername
{
    if([aChatroom.chatroomId isEqualToString:self.chatRoomId] && [self.members containsObject:aUsername]) {
        [self.members removeObject:aUsername];
        [self.admins removeObject:aUsername];
        if(self.delegate && [self.delegate respondsToSelector:@selector(membersDidChanged)])
            [self.delegate membersDidChanged];
    }
}

- (void)chatroomAdminListDidUpdate:(AgoraChatroom *)aChatroom
                        addedAdmin:(NSString *)aAdmin
{
    if(![self.admins containsObject:aAdmin]) {
        [self.admins addObject:aAdmin];
        [self.members removeObjectsInArray:self.admins];
        if(self.delegate && [self.delegate respondsToSelector:@selector(membersDidChanged)])
            [self.delegate membersDidChanged];
    }
}

- (void)chatroomAdminListDidUpdate:(AgoraChatroom *)aChatroom
                        removedAdmin:(NSString *)aAdmin
{
    if([aChatroom.chatroomId isEqualToString:self.chatRoomId] && [self.admins containsObject:aAdmin]) {
        [self.admins removeObject:aAdmin];
        if(self.delegate && [self.delegate respondsToSelector:@selector(membersDidChanged)])
            [self.delegate membersDidChanged];
    }
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
        if(aMembers.count > 0 && [aMembers containsObject:[AgoraChatClient sharedClient].currentUsername]) {
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
        if(aMembers.count > 0 && [aMembers containsObject:[AgoraChatClient sharedClient].currentUsername]) {
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
