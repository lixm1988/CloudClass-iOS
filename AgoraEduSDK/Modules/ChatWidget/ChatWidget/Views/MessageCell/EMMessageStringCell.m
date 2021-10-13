//
//  EMMessageTimeCell.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 2019/2/20.
//  Copyright © 2019 XieYajie. All rights reserved.
//

#import "EMMessageStringCell.h"
#import <Masonry/Masonry.h>
#import "UIImage+ChatExt.h"
#import <HyphenateChat/HyphenateChat.h>

@interface EMMessageStringCell ()
@property (nonatomic,strong) UIView* containerView;
@property (nonatomic,strong) UIButton* reeditButton;
@end

@implementation EMMessageStringCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        //self.contentView.backgroundColor = [UIColor colorWithRed:249/255.0 green:249/255.0 blue:252/255.0 alpha:1.0];
        self.containerView = [[UIView alloc] init];
        self.containerView.backgroundColor = [UIColor colorWithRed:249/255.0 green:249/255.0 blue:252/255.0 alpha:1.0];
        self.containerView.layer.cornerRadius = 4;
        [self.contentView addSubview:self.containerView];
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.contentView);
            make.width.equalTo(self.contentView).offset(-28);
            make.height.equalTo(self.contentView);
        }];
        
        _stringLabel = [[UILabel alloc] init];
        _stringLabel.font = [UIFont systemFontOfSize:12];
        _stringLabel.backgroundColor = [UIColor clearColor];
        _stringLabel.textAlignment = NSTextAlignmentLeft;
        _stringLabel.numberOfLines = 0;
        [self.containerView addSubview:_stringLabel];
        [_stringLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.containerView);
            make.centerX.equalTo(self.containerView).offset(9);
            make.height.equalTo(self.containerView).offset(-8);
            make.width.lessThanOrEqualTo(self.containerView).offset(-50);
        }];
        
        [_stringLabel sizeToFit];
        
        self.preImageView = [[UIImageView alloc] init];
        self.preImageView.image = [UIImage imageNamedFromBundle:@"icon_caution"];
        [self.containerView addSubview:self.preImageView];
        [self.preImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@18);
            make.height.equalTo(@20);
            make.right.equalTo(self.stringLabel.mas_left).offset(-5);
            make.centerY.equalTo(self.containerView);
        }];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updatetext:(NSString*)aText
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:aText];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:5];
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [aText length])];
        self.stringLabel.attributedText = attributedString;
}

- (void)setRecallMsgId:(NSString *)recallMsgId{
    _recallMsgId = recallMsgId;
    if(recallMsgId.length > 0) {
        [self.reeditButton removeFromSuperview];
        EMMessage* msgToDel = [[[EMClient sharedClient] chatManager] getMessageWithMessageId:recallMsgId];
        if([msgToDel.from isEqualToString:[EMClient sharedClient].currentUsername]) {
            [self.containerView addSubview:self.reeditButton];
            [_stringLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.containerView).offset(5);
                make.centerX.equalTo(self.containerView).offset(9);
                make.width.lessThanOrEqualTo(self.containerView).offset(-50);
            }];
            [self.reeditButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(self.stringLabel);
                make.top.equalTo(self.stringLabel.mas_bottom);
            }];
        }
    }else{
        [self.reeditButton removeFromSuperview];
        [self.stringLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.containerView);
            make.centerX.equalTo(self.containerView).offset(9);
            make.height.equalTo(self.containerView).offset(-8);
            make.width.lessThanOrEqualTo(self.containerView).offset(-50);
        }];
    }
}

- (UIButton*)reeditButton
{
    if(!_reeditButton) {
        _reeditButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_reeditButton setTitle:@"重新编辑" forState:UIControlStateNormal];
        _reeditButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_reeditButton addTarget:self action:@selector(reeditAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _reeditButton;
}

- (void)reeditAction
{
    if(self.delegate) {
        [self.delegate reeditMsgId:self.recallMsgId];
    }
}

@end
