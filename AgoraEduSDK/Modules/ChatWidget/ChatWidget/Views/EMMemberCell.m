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

@interface EMMemberCell ()
@property (strong,nonatomic) UIImageView* avatarView;
@property (strong,nonatomic) UILabel* nickName;
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
    [self.contentView addSubview:self.nickName];
    [self.nickName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.avatarView.mas_right).offset(10);
        make.centerY.equalTo(self.contentView);
        make.height.equalTo(self.contentView);
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
}

@end
