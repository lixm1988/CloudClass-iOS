//
//  MembersView.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/16.
//

#import "MembersView.h"
#import "ChatWidget+Localizable.h"
#import <Masonry/Masonry.h>
#import "UIImage+ChatExt.h"
#import "EMMemberCell.h"
#import <HyphenateChat/HyphenateChat.h>
#import "ChatWidgetDefine.h"

@interface MembersView ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
@property (nonatomic,strong) UITextField* searchField;
@property (nonatomic,strong) UITableView* tableView;
@property (nonatomic,strong) NSMutableDictionary* userInfoDic;
@property (nonatomic,strong) NSString* searchText;
@property (nonatomic,strong) NSMutableArray* searchList;
@property (nonatomic,strong) UITapGestureRecognizer* resignRecognizer;
@property (nonatomic,strong) NSLock* dataLock;
@end

@implementation MembersView

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

- (void)setupSubViews
{
    self.backgroundColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0];
    self.searchField = [[UITextField alloc] init];
    self.searchField.placeholder = [ChatWidget LocalizedString:@"ChatSearch"];
    self.searchField.backgroundColor = [UIColor whiteColor];
    self.searchField.font = [UIFont systemFontOfSize:12];
    self.searchField.textColor =  [UIColor colorWithRed:138/255.0 green:138/255.0 blue:154/255.0 alpha:1.0];
    self.searchField.layer.cornerRadius = 2;
    self.searchField.layer.borderWidth = 0.5;
    self.searchField.contentMode = NSTextAlignmentLeft;
    self.searchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    self.searchField.leftView.userInteractionEnabled = NO;
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    self.searchField.delegate = self;
    UIImageView* searchImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    searchImageView.image = [UIImage imageNamedFromBundle:@"icon_search"];
    self.searchField.rightView = searchImageView;
    self.searchField.rightViewMode = UITextFieldViewModeAlways;
    self.searchField.rightView.userInteractionEnabled = NO;
    
    self.searchField.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
    //[self addSubview:self.searchField];
    [self.searchField addTarget:self action:@selector(searchTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
//    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerX.equalTo(self);
//        make.top.equalTo(self).offset(3.5);
//        make.width.equalTo(self).offset(-12);
//        make.height.equalTo(@24);
//    }];
    
    [self addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.top.equalTo(self).offset(5);
        make.bottom.equalTo(self);
    }];
}

- (void)searchTextFieldDidChange:(UITextField*)textField
{
    self.searchText = textField.text;
    [self _searchAction];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)_searchAction
{
    NSMutableArray* arr = [NSMutableArray array];
    if(self.searchText.length > 0) {
        for(NSString* str in self.admins) {
            EMUserInfo* userInfo = [self.userInfoDic objectForKey:str];
            if(userInfo) {
                NSRange range = [userInfo.nickName rangeOfString:self.searchText options:NSCaseInsensitiveSearch];
                if(range.length > 0) {
                    [arr addObject:str];
                }
            }
        }
        for(NSString* str in self.members) {
            EMUserInfo* userInfo = [self.userInfoDic objectForKey:str];
            if(userInfo) {
                NSRange range = [userInfo.nickName rangeOfString:self.searchText options:NSCaseInsensitiveSearch];
                if(range.length > 0) {
                    [arr addObject:str];
                }
            }
        }
    }
    self.searchList = [arr mutableCopy];
}

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

- (NSMutableArray*)admins
{
    if(!_admins) {
        _admins = [NSMutableArray array];
    }
    return _admins;
}

- (NSMutableArray*)members
{
    if(!_members) {
        _members = [NSMutableArray array];
    }
    return _members;
}

- (NSMutableDictionary*)userInfoDic
{
    if(!_userInfoDic) {
        _userInfoDic = [NSMutableDictionary dictionary];
    }
    return _userInfoDic;
}

- (NSMutableArray*)searchList
{
    if(!_searchList) {
        _searchList = [NSMutableArray array];
    }
    return _searchList;
}

- (NSLock*)dataLock
{
    if(!_dataLock) {
        _dataLock = [[NSLock alloc] init];
    }
    return _dataLock;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int count = 0;
    if(self.searchText.length > 0){
        count = [self.searchList count];
        return count;
    }
    [self.dataLock lock];
    count = self.admins.count + self.members.count;
    [self.dataLock unlock];
    return count;
}

- (NSString*)_getUidByCol:(NSUInteger)nCol
{
    NSString* uid = @"";
    if(self.searchText.length > 0) {
        uid = [self.searchList objectAtIndex:nCol];
    }else{
        [self.dataLock lock];
        if(nCol >= self.admins.count && nCol < (self.admins.count+self.members.count)) {
            uid = [self.members objectAtIndex:(nCol - self.admins.count)];
        }else{
            uid = [self.admins objectAtIndex:nCol];
        }
        [self.dataLock unlock];
    }
    return uid;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EMMemberCell *cell = (EMMemberCell*)[tableView dequeueReusableCellWithIdentifier:@"EMMemberCell"];
    // Configure the cell...
    NSUInteger col = indexPath.row;
    NSString* uid = [self _getUidByCol:col];
    if (cell == nil) {
        //cell =[[EMMemberCell alloc] initWithUid:];
        if(uid.length > 0)
        {
            cell = [[EMMemberCell alloc] initWithUid:uid];
            cell.membersView = self;
        }
    }
    if(uid.length > 0) {
        cell.userId = uid;
        EMUserInfo* userInfo = [self.userInfoDic objectForKey:uid];
        if(userInfo) {
            NSUInteger role = [self _getRoleFromExt:userInfo.ext];
            [cell setAvartarUrl:userInfo.avatarUrl nickName:userInfo.nickName role:role];
        }
    }
    
    return cell;
}

- (NSUInteger)_getRoleFromExt:(NSString*)aExt
{
    NSUInteger role = 2;// default student role
    if(aExt.length > 0) {
        NSDictionary* extDic = [NSJSONSerialization JSONObjectWithData:[aExt dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        if(extDic.count > 0) {
            NSNumber* numberVal = [extDic objectForKey:@"role"];
            if(numberVal) {
                role = [numberVal unsignedIntegerValue];
            }
        }
    }
    return role;
}

- (void)updateMembers:(NSArray*)aMembers admins:(NSArray*)admins
{
    [self.dataLock lock];
    [self.admins removeAllObjects];
    [self.members removeAllObjects];
    self.admins = [admins mutableCopy];
    self.members = [aMembers mutableCopy];
    NSArray* array = [self.userInfoDic allKeys];
    NSMutableArray* delArray = [NSMutableArray array];
    for(NSString* uid in array) {
        if(![self.admins containsObject:uid] && ![self.members containsObject:uid])
        {
            [delArray addObject:uid];
        }
    }
    [self.dataLock unlock];
    [self.searchList removeObjectsInArray:delArray];
    [self.userInfoDic removeObjectsForKeys:delArray];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fetchUserInfo) object:nil];
    [self performSelector:@selector(fetchUserInfo) withObject:nil afterDelay:0.1];
}

- (void)fetchUserInfo
{
    NSMutableArray* array = [NSMutableArray array];
    for (NSString* uid in self.admins) {
        if(![self.userInfoDic objectForKey:uid]) {
            [array addObject:uid];
        }
    }
    for (NSString* uid in self.members) {
        if(![self.userInfoDic objectForKey:uid]) {
            [array addObject:uid];
        }
    }
    NSInteger count = array.count;
    int index = 0;
    __weak typeof(self) weakself = self;
    while (count > 0) {
        NSRange range;
        range.location = 100*index;
        if(count > 100) {
            range.length = 100;
        }else
            range.length = count;
        NSArray* arr = [array subarrayWithRange:range];
        if(arr.count <= 0)
            return;
        [[[EMClient sharedClient] userInfoManager] fetchUserInfoById:arr completion:^(NSDictionary *aUserDatas, EMError *aError) {
            if(!aError) {
                if(aUserDatas.count > 0) {
                    for (NSString* uid in aUserDatas) {
                        EMUserInfo* userInfo = [aUserDatas objectForKey:uid];
                        if(uid.length > 0 && userInfo)
                        {
                            [weakself.userInfoDic setObject:userInfo forKey:uid];
                            NSUInteger role = [weakself _getRoleFromExt:userInfo.ext];
                            if(ROLE_IS_TEACHER(role)) {
                                [weakself.dataLock lock];
                                [weakself.members removeObject:uid];
                                [weakself.admins removeObject:uid];
                                if(![weakself.admins containsObject:uid]) {
                                    if(ROLE_IS_TEACHER(role)) {
                                        [weakself.admins insertObject:uid atIndex:0];
                                    }else
                                        [weakself.admins addObject:uid];
                                }
                                [weakself.dataLock unlock];
                            }
                        }
                    }
                    [weakself _searchAction];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself.tableView reloadData];
                    });
                    
                }
            }
            
        }];
        count -= 100;
    }
}

- (void)updateMuteMembers:(NSArray*)muteMembers
{
    self.muteMembers = [muteMembers mutableCopy];
    [self.tableView reloadData];
}

- (UIGestureRecognizer*)resignRecognizer
{
    if(!_resignRecognizer) {
        _resignRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchOutside:)];
        _resignRecognizer.cancelsTouchesInView = NO;
        _resignRecognizer.enabled = YES;
        _resignRecognizer.delegate = self;
    }
    return _resignRecognizer;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.window becomeFirstResponder];
    [self.window addGestureRecognizer:self.resignRecognizer];
}

// 失去焦点
- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self.window removeGestureRecognizer:self.resignRecognizer];
}

- (void)touchOutside:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.window resignFirstResponder];
        [self.window endEditing:YES];
    }
}

@end
