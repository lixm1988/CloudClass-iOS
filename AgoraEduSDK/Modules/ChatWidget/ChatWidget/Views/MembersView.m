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
        make.height.equalTo(@12);
    }];
}

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    return _tableView;
}

@end
