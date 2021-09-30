//
//  EMMemberCell.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/22.
//

#import "EMMemberCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+ChatExt.h"
#import "ChatWidget+Localizable.h"
#import "ChatWidgetDefine.h"
#import <HyphenateChat/HyphenateChat.h>

@interface EMMemberCell ()
@property (strong,nonatomic) UIImageView* avatarView;
@property (strong,nonatomic) UILabel* nickName;
@property (nonatomic, strong) UITextField *roleTag;
@property (nonatomic,strong) UIButton* muteButton;
@end

@implementation EMMemberCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithUid:(NSString*)aUid
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EMMemberCell"];
    if(self) {
        self.userId = aUid;
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews
{
    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.image = [UIImage imageNamedFromBundle:@"user_avatar_blue"];
    [self.contentView addSubview:self.avatarView];
    [self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@24);
        make.left.equalTo(self.contentView).offset(10);
        //make.centerY.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(10);
        make.bottom.equalTo(self.contentView).offset(-10);
    }];
    
    self.nickName = [[UILabel alloc] init];
    self.nickName.text = self.userId;
    self.nickName.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:self.nickName];
    [self.nickName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarView.mas_right).offset(10);
        make.centerY.equalTo(self.contentView);
        make.height.equalTo(self.contentView);
    }];
    
    _roleTag = [[UITextField alloc] init];
    _roleTag.font = [UIFont systemFontOfSize:12];
    _roleTag.textColor = [UIColor colorWithRed:88/255.0 green:99/255.0 blue:118/255.0 alpha:1.0];
    _roleTag.layer.cornerRadius = 8;
    _roleTag.layer.borderWidth = 1;
    _roleTag.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
    _roleTag.hidden = YES;
    _roleTag.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 0)];
    _roleTag.leftViewMode = UITextFieldViewModeAlways;
    _roleTag.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 0)];
    _roleTag.rightViewMode = UITextFieldViewModeAlways;
    _roleTag.enabled = NO;
    [self.contentView addSubview:_roleTag];
    [_roleTag mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nickName.mas_right).offset(10);
        make.centerY.equalTo(self.contentView);
    }];
}

- (void)setAvartarUrl:(NSString*)aUrl nickName:(NSString*)nickName role:(NSUInteger)role
{
    if(aUrl.length > 0) {
        NSURL* url = [NSURL URLWithString:aUrl];
        if(url) {
            [self.avatarView sd_setImageWithURL:url completed:nil];
        }
    }
    if(nickName.length > 0) {
        self.nickName.text = nickName;
    }
    switch (role) {
        case 0:
            self.roleTag.hidden = YES;
            break;
        case 1:
            self.roleTag.text = [ChatWidget LocalizedString:@"ChatTeacher"];
            self.roleTag.hidden = NO;
            if(ROLE_IS_TEACHER(self.membersView.chatManager.user.role))
                self.muteButton.hidden = YES;
            break;
        case 2:
            self.roleTag.hidden = YES;
            [self updateMuteState];
            break;
        case 3:
            self.roleTag.text = [ChatWidget LocalizedString:@"ChatAssistant"];
            self.roleTag.hidden = NO;
            if(ROLE_IS_TEACHER(self.membersView.chatManager.user.role))
                self.muteButton.hidden = YES;
            break;
        default:
            break;
    }
}

- (UIButton*)muteButton
{
    if(!_muteButton) {
        _muteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_muteButton setImage:[UIImage imageNamedFromBundle:@"icon_mute"] forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamedFromBundle:@"icon_unmute"] forState:UIControlStateSelected];
        [_muteButton addTarget:self action:@selector(muteAction) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_muteButton];
        [_muteButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView).offset(-5);
            make.width.height.equalTo(@24);
            make.centerY.equalTo(self.contentView);
        }];
    }
    return _muteButton;
}

- (void)muteAction
{
    [self.membersView.chatManager muteMember:self.userId mute:!self.muteButton.isSelected];
}

- (void)updateMuteState
{
    if(ROLE_IS_TEACHER(self.membersView.chatManager.user.role)) {
        self.muteButton.hidden = NO;
        [self.muteButton setSelected:[self.membersView.muteMembers containsObject:self.userId]];
    }
}

@end
