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
    self.nilMsgLable.textColor =  [UIColor colorWithRed:125/255.0 green:135/255.0 blue:152/255.0 alpha:1.0];
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
// 新消息按钮
@property (nonatomic, strong) UIButton* newMsgsButton;
// 消息列表是否在最底部
@property (nonatomic) BOOL curMsgInBottom;
// 新消息条数统计
@property (atomic) NSUInteger newMsgsCount;
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
        self.curMsgInBottom = YES;
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
            make.bottom.equalTo(self).offset(-CHATBAR_HEIGHT-5);
    }];
    [self.chatBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.right.equalTo(self).offset(-5);
        make.left.equalTo(self).offset(5);
        make.height.equalTo(@CHATBAR_HEIGHT);
    }];
    [self.nilQAMsgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.bottom.equalTo(self).offset(-CHATBAR_HEIGHT-5);
    }];
    
    [self addSubview:self.newMsgsButton];
    [self.newMsgsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.tableView);
        make.bottom.equalTo(self.tableView).offset(-5);
        make.width.equalTo(@120);
        make.height.equalTo(@22);
    }];
    [self bringSubviewToFront:self.newMsgsButton];
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
    self.curMsgInBottom = YES;
    ChatMsgType type = self.asker.length == 0?ChatMsgTypeAsk:ChatMsgTypeAnswer;
    [self.delegate msgWillSend:aMsgText type:type asker:self.asker];
}

- (void)imageDataWillSend:(NSData *)aImageData
{
    ChatMsgType type = self.asker.length == 0?ChatMsgTypeAsk:ChatMsgTypeAnswer;
    [self.delegate imageDataWillSend:aImageData type:type asker:self.asker];
}
@end
