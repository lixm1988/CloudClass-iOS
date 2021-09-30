//
//  QaUserCell.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/9/13.
//

#import "QaUserCell.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface QaUserCell()
@property (nonatomic,strong) UIImageView* avatarImageView;
@property (nonatomic,strong) UILabel* nickNameLable;
@property (nonatomic,strong) UILabel* tsLable;
@property (nonatomic,strong) UILabel* msgLable;
@property (nonatomic,strong) UIView* badgeView;
@property (nonatomic,strong) NSString* uid;
@end

@implementation QaUserCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithUid:(NSString*)uid model:(QaUserModel *)model
{
    self = [super init];
    if(self) {
        self.uid = uid;
        self.model = model;
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews
{
    [self.contentView addSubview:self.avatarImageView];
    [self.contentView addSubview:self.msgLable];
    [self.contentView addSubview:self.tsLable];
    [self.contentView addSubview:self.badgeView];
    [self.contentView addSubview:self.nickNameLable];
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.equalTo(@32);
        make.left.top.equalTo(self.contentView).offset(3);
    }];
    [self.nickNameLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.avatarImageView.mas_right).offset(10);
            make.top.equalTo(self.avatarImageView);
            make.height.equalTo(@20);
    }];
    [self.tsLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-5);
        make.top.height.equalTo(self.nickNameLable);
    }];
    [self.msgLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.height.equalTo(self.nickNameLable);
        make.bottom.equalTo(self.contentView).offset(-3);
    }];
    [self.badgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.avatarImageView).offset(-2);
        make.top.equalTo(self.avatarImageView).offset(2);
        make.width.height.equalTo(@6);
    }];
    self.badgeView.layer.cornerRadius = 3;
    self.badgeView.hidden = YES;
    [self updateUserInfo];
    [self updateLatestMsg];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(qaUserCellTapAction:)];
    [self.contentView addGestureRecognizer:tap];
}

- (void)qaUserCellTapAction:(UITapGestureRecognizer *)aTap
{
    if (aTap.state == UIGestureRecognizerStateEnded) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(qaUserCellDidSelected:)]) {
            [self.delegate qaUserCellDidSelected:self];
        }
    }
}

- (void)updateLatestMsg
{
    if(self.model && self.model.msgArray.count > 0) {
        EMMessage*msg = [self.model.msgArray lastObject];
        if(msg) {
            NSDate* date = [NSDate dateWithTimeIntervalSince1970:msg.timestamp/1000];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"HH:mm"];
            self.tsLable.text = [formatter stringFromDate:date];
            if(msg.body.type == EMMessageBodyTypeText) {
                EMTextMessageBody* textBody = (EMTextMessageBody*)msg.body;
                self.msgLable.text = textBody.text;
            }
        }
    }
    
}

- (void)updateUserInfo
{
    NSString* nickName = nil;
    NSString* avatarUrl = nil;
    if(_model && _model.msgArray.count > 0) {
        for(EMMessage* msg in _model.msgArray) {
            NSNumber* type = [msg.ext objectForKey:@"msgType"];
            if(type.integerValue == 1) {
                nickName = [msg.ext objectForKey:@"nickName"];
                avatarUrl = [msg.ext objectForKey:@"avatarUrl"];
                break;
            }
        }
    }
    if(nickName.length == 0 || avatarUrl.length == 0) {
        if( self.uid.length > 0) {
            __weak typeof(self) weakself = self;
            [[[EMClient sharedClient] userInfoManager] fetchUserInfoById:@[self.uid] completion:^(NSDictionary *aUserDatas, EMError *aError) {
                if(!aError) {
                    EMUserInfo* userInfo = [aUserDatas objectForKey:weakself.uid];
                    if(userInfo) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(userInfo.nickName.length > 0)
                                weakself.nickNameLable.text = userInfo.nickName;
                            if(userInfo.avatarUrl.length > 0) {
                                NSURL* url = [NSURL URLWithString:userInfo.avatarUrl];
                                if(url) {
                                    [weakself.avatarImageView sd_setImageWithURL:url completed:nil];
                                }
                            }
                        });
                    }
                }
            }];
        }
    }else{
        self.textLabel.text = nickName;
        NSURL* url = [NSURL URLWithString:avatarUrl];
        if(url) {
            [self.avatarImageView sd_setImageWithURL:url completed:nil];
        }
    }
}

#pragma mark - setter
- (void)setModel:(QaUserModel *)model
{
    _model = model;
    [self updateUserInfo];
    [self updateLatestMsg];
}

#pragma mark - getter
- (UIImageView*)avatarImageView
{
    if(!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
    }
    return _avatarImageView;
}

- (UILabel*)nickNameLable
{
    if(!_nickNameLable) {
        _nickNameLable = [[UILabel alloc] init];
        _nickNameLable.font = [UIFont systemFontOfSize:12];
    }
    return _nickNameLable;
}

- (UILabel*)tsLable
{
    if(!_tsLable) {
        _tsLable = [[UILabel alloc] init];
        _tsLable.font = [UIFont systemFontOfSize:10];
        _tsLable.textColor = [UIColor colorWithRed:123/255.0 green:136/255.0 blue:160/255.0 alpha:1.0];
    }
    return _tsLable;
}

- (UILabel*)msgLable
{
    if(!_msgLable) {
        _msgLable = [[UILabel alloc] init];
        _msgLable.font = [UIFont systemFontOfSize:10];
        _msgLable.textColor = [UIColor colorWithRed:123/255.0 green:136/255.0 blue:160/255.0 alpha:1.0];
    }
    return _msgLable;
}

- (UIView*)badgeView
{
    if(!_badgeView) {
        _badgeView = [[UIView alloc] init];
        _badgeView.backgroundColor = [UIColor redColor];
    }
    return _badgeView;
}


- (void)setShowRedNotice:(BOOL)showRedNotice
{
    _showRedNotice = showRedNotice;
    self.badgeView.hidden = !showRedNotice;
}

@end
