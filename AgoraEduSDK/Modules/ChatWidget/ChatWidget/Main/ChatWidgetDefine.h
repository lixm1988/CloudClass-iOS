//
//  ChatWidgetDefine.h
//  AgoraEducation
//
//  Created by lixiaoming on 2021/5/17.
//  Copyright © 2021 Agora. All rights reserved.
//

#ifndef ChatWidgetDefine_h
#define ChatWidgetDefine_h

typedef NS_ENUM(NSUInteger, ChatMsgType) {
    ChatMsgTypeCommon = 0,
    ChatMsgTypeAsk,
    ChatMsgTypeAnswer,
};

typedef NS_ENUM(NSUInteger, ChatRoomState) {
    ChatRoomStateLogin = 0,
    ChatRoomStateLogined,
    ChatRoomStateLoginFailed,
    ChatRoomStateJoining,
    ChatRoomStateJoined,
    ChatRoomStateJoinFail,
};

typedef NS_ENUM(NSInteger, AgoraRTERoleType) {
    AgoraRTERoleTypeInvalid = 0,
    AgoraRTERoleTypeTeacher = 1,
    AgoraRTERoleTypeStudent = 2,
    AgoraRTERoleTypeAssistant = 3,
};

#define ROLE_IS_TEACHER(role) ((role) == 1 || (role) == 3)

#endif /* ChatWidgetDefine_h */
