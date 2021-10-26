//
//  QAView.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/16.
//

#import "QAView.h"
#import <Masonry/Masonry.h>
#import "EMMessageModel.h"
#import "EMMessageStringCell.h"
#import "EMMessageCell.h"
#import "ChatWidget+Localizable.h"
#import "UIImage+ChatExt.h"

#define CHATBAR_HEIGHT 30

@interface NilQAMessagesView()
@property (nonatomic,strong) UIImageView*nilMsgImageView;
@property (nonatomic,strong) UILabel* nilMsgLable;
@end

@implementation NilQAMessagesView

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
        make.centerY.equalTo(self).offset(-20);
        make.width.equalTo(@80);
        make.height.equalTo(@72);
    }];
    
    self.nilMsgLable = [[UILabel alloc] init];
    self.nilMsgLable.text = [ChatWidget LocalizedString:@"ChatEmptyQA"];
    self.nilMsgLable.font = [UIFont systemFontOfSize:12];
    self.nilMsgLable.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.nilMsgLable];
    [self.nilMsgLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nilMsgImageView.mas_bottom).offset(5);
        make.centerX.equalTo(self);
        make.height.equalTo(@20);
        make.width.equalTo(self);
    }];
}

@end

@interface QAView ()
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, nonatomic) NSMutableArray *msgIdArray;
@property (nonatomic, strong) NSMutableArray<NSString*>* msgsToDel;
@property (nonatomic, strong) NilQAMessagesView* nilQAMsgView;
@end

@implementation QAView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        [self setupSubViews];
    }
    return self;
}

-(void)setupSubViews
{
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.tableView];
    
    
    [self addSubview:self.chatBar];
    [self bringSubviewToFront:self.chatBar];
    [self sendSubviewToBack:self.tableView];
    
    [self addSubview:self.nilQAMsgView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.width.equalTo(self);
            make.bottom.equalTo(self).offset(-CHATBAR_HEIGHT);
    }];
    [self.chatBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.right.equalTo(self).offset(-10);
        make.left.equalTo(self).offset(10);
        make.height.equalTo(@CHATBAR_HEIGHT);
    }];
    [self.nilQAMsgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.bottom.equalTo(self).offset(-CHATBAR_HEIGHT);
    }];
}

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

- (ChatBar*)chatBar
{
    if(!_chatBar) {
        _chatBar = [[ChatBar alloc] init];
        _chatBar.delegate = self;
        _chatBar.layer.cornerRadius = 15;
    }
    return _chatBar;
}

- (NSMutableArray *)dataArray
{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
    }
    
    return _dataArray;
}

-(NSMutableArray*)msgIdArray
{
    if(!_msgIdArray) {
        _msgIdArray = [NSMutableArray array];
    }
    return _msgIdArray;
}

- (NSMutableArray<NSString*>*)msgsToDel
{
    if(!_msgsToDel) {
        _msgsToDel = [NSMutableArray<NSString*> array];
    }
    return _msgsToDel;
}

-(NilQAMessagesView*)nilQAMsgView
{
   if(!_nilQAMsgView) {
       _nilQAMsgView = [[NilQAMessagesView alloc] init];
   }
   return _nilQAMsgView;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    self.nilQAMsgView.hidden = self.dataArray.count > 0;
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id obj = [self.dataArray objectAtIndex:indexPath.row];
    NSString *cellString = nil;
    if ([obj isKindOfClass:[NSString class]]) {
        cellString = (NSString *)obj;
    } else if ([obj isKindOfClass:[EMMessageModel class]]) {
        EMMessageModel *model = (EMMessageModel *)obj;
        if (model.type == EMMessageTypeExtRecall) {
            cellString = [ChatWidget LocalizedString:@"ChatRecallAMessage"];
        }
    }
    if ([cellString length] > 0) {
        EMMessageStringCell *cell = (EMMessageStringCell *)[tableView dequeueReusableCellWithIdentifier:@"EMMessageStringCell"];
        // Configure the cell...
        if (cell == nil) {
            cell = [[EMMessageStringCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EMMessageStringCell"];
        }

        [cell updatetext:cellString];
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

- (void)scrollToBottomRow
{
    if ([self.dataArray count] > 0) {
        [self.tableView setNeedsLayout];
        [self.tableView layoutIfNeeded];
        NSInteger toRow = self.dataArray.count - 1;
        NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:toRow inSection:0];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView scrollToRowAtIndexPath:toIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
        [weakself scrollToBottomRow];
    });
}

- (void)resetMsgs
{
    [self.dataArray removeAllObjects];
    [self.msgIdArray removeAllObjects];
    [self.msgsToDel removeAllObjects];
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
            continue;
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
        
        EMMessageModel *model = [[EMMessageModel alloc] initWithEMMessage:msg];
        [formated addObject:model];
    }
    
    return formated;
}

#pragma mark - ChatBarDelegate
- (void)msgWillSend:(NSString*)aMsgText
{
    ChatMsgType type = self.asker.length == 0?ChatMsgTypeAsk:ChatMsgTypeAnswer;
    [self.delegate msgWillSend:aMsgText type:type asker:self.asker];
}

- (void)imageDataWillSend:(NSData *)aImageData
{
    ChatMsgType type = self.asker.length == 0?ChatMsgTypeAsk:ChatMsgTypeAnswer;
    [self.delegate imageDataWillSend:aImageData type:type asker:self.asker];
}
@end
