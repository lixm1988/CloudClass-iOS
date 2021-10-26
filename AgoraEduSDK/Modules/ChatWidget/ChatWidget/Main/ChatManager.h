//
//  ChatManager.h
//  AgoraEducation
//
//  Created by lixiaoming on 2021/5/12.
//  Copyright © 2021 Agora. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatUserConfig.h"
#import "ChatWidgetDefine.h"
#import <AgoraChat/AgoraChat.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ChatManagerDelegate <NSObject>

// 需要展示接收消息
- (void)chatMessageDidReceive;
// 需要展示提问消息
- (void)qaMessageDidReceive;
// 需要展示发送消息
- (void)chatMessageDidSend:(AgoraChatMessage*)aMessage;
// 需要展示发送的提问消息
- (void)qaMessageDidSend:(AgoraChatMessage*)aMessage;
// 发生异常
- (void)exceptionDidOccur:(NSString*)aErrorDescription;
// 需要撤回消息
- (void)chatMessageDidRecall:(NSString*)aMessageId;
// 禁言状态改变
- (void)mutedStateDidChanged;
// 状态发生改变
- (void)roomStateDidChanged:(ChatRoomState)aState;
// 公告发生变更
- (void)announcementDidChanged:(NSString*)aAnnouncement isFirst:(BOOL)aIsFirst;
// 成员列表发生变更
- (void)membersDidChanged;
// 禁言列表发生变更
- (void)muteMembersDidChannged;

@end

@interface ChatManager : NSObject

// 初始化
- (instancetype)initWithUserConfig:(ChatUserConfig*)aUserConfig
                            appKey:(NSString *)appKey
                          password:(NSString *)password
                        chatRoomId:(NSString*)aChatRoomId;
// 启动
- (void)launch;
// 退出
- (void)logout;
- (void)sendTextMsg:(NSString*)aText msgType:(ChatMsgType)aType asker:(NSString*)aAsker;
- (void)muteAll:(BOOL)aMuteAll;
// 发送提问消息
- (void)sendImageMsgWithData:aImageData msgType:(ChatMsgType)aType asker:(NSString*)aAsker;
// 获取用户配置
- (ChatUserConfig*)userConfig;
// 接收的消息
- (NSArray<AgoraChatMessage*> *)msgArray;
// 接收的消息
- (NSArray<AgoraChatMessage*> *)qaArray;
// 更新头像
- (void)updateAvatar:(NSString*)avatarUrl;
// 更新昵称
- (void)updateNickName:(NSString*)nickName;
// 禁言用户
- (void)muteMember:(NSString*)aUserId mute:(BOOL)aMute;
// 删除消息
- (void)deleteMessage:(NSString*)aMsgId;
// 发布公告
- (void)publishAnnouncement:(NSString*)aAnnouncement;
@property (nonatomic) BOOL isAllMuted;
@property (nonatomic) BOOL isMuted;
@property (nonatomic,strong) ChatUserConfig* user;
@property (nonatomic,strong) NSString* chatRoomId;
@property (nonatomic) BOOL enableQAChatroom;
@property (nonatomic,strong) NSString* qaChatRoomId;
@property (nonatomic,strong) NSString* chatroomAnnouncement;
@property (nonatomic,weak) id<ChatManagerDelegate> delegate;
@property (nonatomic) ChatRoomState state;
@property (nonatomic,strong) NSMutableArray* admins;
@property (nonatomic,strong) NSMutableArray* members;
@property (nonatomic,strong) NSMutableArray* muteMembers;
@property (nonatomic) BOOL hasNewMsgs;
@end

NS_ASSUME_NONNULL_END
