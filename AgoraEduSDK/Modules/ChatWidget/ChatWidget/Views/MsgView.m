//
//  MsgView.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/16.
//

#import "MsgView.h"
#import <Masonry/Masonry.h>
#import "EMMessageModel.h"
#import "EMMessageStringCell.h"
#import "EMMessageCell.h"
#import "ChatWidget+Localizable.h"

@interface MsgView ()
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, nonatomic) NSMutableArray *msgIdArray;
@property (nonatomic, strong) NSMutableArray<NSString*>* msgsToDel;
@end

@implementation MsgView

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
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.width.equalTo(self);
            make.bottom.equalTo(self).offset(-40);
    }];
    [self.chatBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.width.equalTo(self);
        make.height.equalTo(@40);
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
        _chatBar.parantView = self;
        _chatBar.delegate = self;
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

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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

- (void)updateMsgs:(NSMutableArray<EMMessage*>*)msgArray
{
    NSArray *formated = [self _formatMessages:msgArray];
    [self.dataArray addObjectsFromArray:formated];
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself.tableView reloadData];
        [weakself scrollToBottomRow];
    });
}

- (NSArray *)_formatMessages:(NSArray<EMMessage *> *)aMessages
{
    NSMutableArray *formated = [[NSMutableArray alloc] init];

    for (int i = 0; i < [aMessages count]; i++) {
        EMMessage *msg = aMessages[i];
        if([self.msgIdArray containsObject:msg.messageId]) {
            continue;
        }else{
            [self.msgIdArray addObject:msg.messageId];
        }
        // cmd消息不展示
        if(msg.body.type == EMMessageBodyTypeCmd) {
            continue;
        }
        if(msg.body.type == EMMessageBodyTypeCustom) {
            continue;
        }
        if (msg.chatType == EMChatTypeChat && !msg.isReadAcked && (msg.body.type == EMMessageBodyTypeText || msg.body.type == EMMessageBodyTypeLocation)) {
            if([self.msgsToDel containsObject:msg.messageId])
                continue;
            [[EMClient sharedClient].chatManager sendMessageReadAck:msg.messageId toUser:msg.conversationId completion:nil];
        } else if (msg.chatType == EMChatTypeGroupChat && !msg.isReadAcked && (msg.body.type == EMMessageBodyTypeText || msg.body.type == EMMessageBodyTypeLocation)) {
        }
        
        EMMessageModel *model = [[EMMessageModel alloc] initWithEMMessage:msg];
        [formated addObject:model];
    }
    
    return formated;
}

#pragma mark - ChatBarDelegate
- (void)msgWillSend:(NSString*)aMsgText
{
    [self.delegate msgWillSend:aMsgText type:ChatMsgTypeAsk];
}
@end
