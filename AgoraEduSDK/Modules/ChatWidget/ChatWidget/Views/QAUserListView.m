//
//  QAUserListView.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/9/9.
//

#import "QAUserListView.h"
#import "UIImage+ChatExt.h"
#import "ChatWidget+Localizable.h"
#import <Masonry/Masonry.h>
#import "QaUserModel.h"
#import "QaUserCell.h"
#import "TeacherQAView.h"

@interface QAUserListView ()<UITableViewDelegate,UITableViewDataSource,QaUserCellDelegate,TeacherQAViewDelegate>
@property (nonatomic,strong) UITableView* qaUserListView;
@property (nonatomic,strong) NSMutableArray* qaMsgs;
@property (nonatomic,strong) NilQAMessagesView* nilQAUsersView;
@property (nonatomic,strong) NSLock*dataLock;
@property (nonatomic,strong) TeacherQAView* currentQAView;
@property (nonatomic) BOOL showQAView;
@property (nonatomic,strong) NSMutableDictionary* latestMsgs;
@property (nonatomic,strong) NSMutableSet* showRedNoticeUsers;
@end

@implementation QAUserListView

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
    [self addSubview:self.nilQAUsersView];
    [self addSubview:self.qaUserListView];
    [self.nilQAUsersView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.qaUserListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    self.qaUserListView.hidden = YES;
}

- (NilQAMessagesView*)nilQAUsersView
{
    if(!_nilQAUsersView) {
        _nilQAUsersView = [[NilQAMessagesView alloc] init];
    }
    return _nilQAUsersView;
}

- (UITableView*)qaUserListView
{
    if(!_qaUserListView) {
        _qaUserListView = [[UITableView alloc] init];
        _qaUserListView.delegate = self;
        _qaUserListView.dataSource = self;
        _qaUserListView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _qaUserListView.allowsSelection = YES;
        _qaUserListView.userInteractionEnabled = YES;
        _qaUserListView.tableFooterView = [UIView new];
    }
    return _qaUserListView;
}

- (void)updateMsgs:(NSMutableArray<EMMessage*>*)msgArray
{
    [self.dataLock lock];
    for (EMMessage*msg in msgArray) {
        NSString* asker = [msg.ext objectForKey:@"asker"];
        if(asker.length > 0) {
            NSInteger index = [self getUserModelIndexByUid:asker];
            if(index < 0) {
                QaUserModel*model = [[QaUserModel alloc] init];
                model.userId = asker;
                [model pushMsg:msg];
                [self.qaMsgs insertObject:model atIndex:0];
            }else{
                QaUserModel*model = [self.qaMsgs objectAtIndex:index];
                [model pushMsg:msg];
                if(index > 0) {
                    [self.qaMsgs removeObjectAtIndex:index];
                    [self.qaMsgs insertObject:model atIndex:0];
                }
            }
            if([self.currentQAView.qaView.asker isEqualToString:asker]) {
                [self saveReadMsg:msg.messageId asker:asker];
                [self.currentQAView.qaView updateMsgs:@[msg]];
            }else{
                NSString*latestMsgId = [self.latestMsgs objectForKey:asker];
                if(latestMsgId.length <=  0 || [msg.messageId compare:latestMsgId] == NSOrderedDescending) {
                    [self.showRedNoticeUsers addObject:asker];
                    [self showRedNotice:YES];
                }else{
                    [self showRedNotice:NO];
                }
            }
        }
    }
    [self.dataLock unlock];
    if(!self.showQAView) {
        if(!self.nilQAUsersView.isHidden)
            self.nilQAUsersView.hidden = YES;
        if(self.qaUserListView.isHidden)
            self.qaUserListView.hidden = NO;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refresh) object:nil];
    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.3];
}

- (void)showRedNotice:(BOOL)showRedNotice
{
    ChatWidget* widget = (ChatWidget*)self.parantView;
    [widget showQARedNotice:showRedNotice];
}

- (void)refresh
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself.qaUserListView reloadData];
    });
}

- (void)_getReadMsgs
{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userName = self.chatManager.user.username;
    if(userName.length > 0)
    {
        NSDictionary* dic = [userDefault objectForKey:userName];
        self.latestMsgs = [dic mutableCopy];
    }
}

- (void)setChatManager:(ChatManager *)chatManager
{
    _chatManager = chatManager;
    [self _getReadMsgs];
}

- (void)saveReadMsg:(NSString*)msgId asker:(NSString*)asker
{
    if(msgId.length > 0 && asker.length > 0) {
        [self.latestMsgs setObject:msgId forKey:asker];
    }
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* userName = [EMClient sharedClient].currentUsername;
    if(userName.length > 0 && self.latestMsgs.count > 0)
        [userDefault setObject:self.latestMsgs forKey:userName];
}

- (NSMutableArray*)qaMsgs
{
    if(!_qaMsgs) {
        _qaMsgs = [NSMutableArray array];
    }
    return _qaMsgs;
}

- (NSMutableDictionary*)latestMsgs
{
    if(!_latestMsgs) {
        _latestMsgs = [NSMutableDictionary dictionary];
    }
    return _latestMsgs;
}

- (NSMutableSet*)showRedNoticeUsers
{
    if(!_showRedNoticeUsers) {
        _showRedNoticeUsers = [NSMutableSet set];
    }
    return _showRedNoticeUsers;
}

- (NSInteger)getUserModelIndexByUid:(NSString*)uid
{
    for(NSInteger index = 0;index < self.qaMsgs.count;index++) {
        QaUserModel* model = [self.qaMsgs objectAtIndex:index];
        if([uid isEqualToString:model.userId])
        {
            return index;
        }
    }
    return -1;
}

- (NSLock*)dataLock
{
    if(!_dataLock) {
        _dataLock = [[NSLock alloc] init];
    }
    return _dataLock;
}

- (TeacherQAView*)currentQAView
{
    if(!_currentQAView) {
        _currentQAView = [[TeacherQAView alloc] init];
    }
    return _currentQAView;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.qaMsgs count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    QaUserCell *cell = (QaUserCell *)[tableView dequeueReusableCellWithIdentifier:@"QaUserCell"];
    QaUserModel* model = [self.qaMsgs objectAtIndex:indexPath.row];
    if (cell == nil) {
        cell = [[QaUserCell alloc] initWithUid:model.userId model:model];
        cell.delegate = self;
    }
    [cell setModel:model];
    cell.showRedNotice = [self.showRedNoticeUsers containsObject:model.userId];
    return cell;
}

#pragma mark - QaUserCellDelegate
- (void)qaUserCellDidSelected:(UITableViewCell *)aCell
{
    QaUserCell* cell = (QaUserCell*)aCell;
    if(![self.subviews containsObject:self.currentQAView])
    {
        [self addSubview:self.currentQAView];
        [self.currentQAView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        self.currentQAView.qaView.asker = cell.model.userId;
        if(self.parantView)
            self.currentQAView.qaView.delegate = self.parantView;
    }
    [self.currentQAView resetMsgs:cell.model.msgArray];
    EMMessage* msg = cell.model.msgArray.lastObject;
    [self saveReadMsg:msg.messageId  asker:cell.model.userId];
    [self.showRedNoticeUsers removeObject:cell.model.userId];
    if(self.showRedNoticeUsers.count <= 0)
    {
        // 问答不显示红点
    }
    cell.showRedNotice = NO;
}

#pragma mark - TeacherQAViewDelegate
- (void)teacherQAViewDidClose
{
    self.qaUserListView.hidden = NO;
    self.showQAView = NO;
}
@end
