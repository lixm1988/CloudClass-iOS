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

@interface MembersView ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong) UITextField* searchField;
@property (nonatomic,strong) UITableView* tableView;
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
    UIImageView* searchImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    searchImageView.image = [UIImage imageNamedFromBundle:@"icon_search"];
    self.searchField.rightView = searchImageView;
    self.searchField.rightViewMode = UITextFieldViewModeAlways;
    self.searchField.rightView.userInteractionEnabled = NO;
    
    self.searchField.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
    [self addSubview:self.searchField];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(3.5);
        make.width.equalTo(self).offset(-12);
        make.height.equalTo(@24);
    }];
    
    [self addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.top.equalTo(self.searchField.mas_bottom).offset(5);
        make.bottom.equalTo(self);
    }];
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

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.admins count] + [self.members count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EMMemberCell *cell = (EMMemberCell*)[tableView dequeueReusableCellWithIdentifier:@"EMMemberCell"];
    // Configure the cell...
    if (cell == nil) {
        //cell =[[EMMemberCell alloc] initWithUid:];
        int col = indexPath.row;
        if(col >= self.admins.count && col < (self.admins.count+self.members.count)) {
            NSString* uid = [self.members objectAtIndex:(col - self.admins.count)];
            if(uid.length)
                cell = [[EMMemberCell alloc] initWithUid:uid];
        }else{
            NSString* uid = [self.admins objectAtIndex:col];
            if(uid.length)
                cell = [[EMMemberCell alloc] initWithUid:uid];
        }
    }
    return cell;
}

- (void)update
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
