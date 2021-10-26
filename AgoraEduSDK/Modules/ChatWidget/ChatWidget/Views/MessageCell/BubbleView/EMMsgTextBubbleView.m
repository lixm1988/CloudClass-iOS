//
//  EMMsgTextBubbleView.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 2019/2/14.
//  Copyright © 2019 XieYajie. All rights reserved.
//

#import "EMMsgTextBubbleView.h"
#import "EMEmojiHelper.h"

@implementation EMMsgTextBubbleView

- (instancetype)initWithDirection:(AgoraChatMessageDirection)aDirection
                             type:(EMMessageType)aType
{
    self = [super initWithDirection:aDirection type:aType];
    if (self) {
        [self _setupSubviews];
    }
    
    return self;
}

#pragma mark - Subviews

- (void)_setupSubviews
{
    [self setupBubbleBackgroundImage];
    
    self.textLabel = [[UILabel alloc] init];
    self.textLabel.font = [UIFont systemFontOfSize:12];
    self.textLabel.numberOfLines = 0;
    [self addSubview:self.textLabel];
    [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(20);
        make.bottom.equalTo(self).offset(-10);
    }];
    
    self.textLabel.textColor = [UIColor blackColor];
    if (self.direction == AgoraChatMessageDirectionSend) {
        [self.textLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(10);
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self).offset(-15);
        }];
    } else {
        [self.textLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(10);
            make.left.equalTo(self).offset(15);
            make.right.equalTo(self).offset(-10);
        }];
    }
}

#pragma mark - Setter

- (void)setModel:(EMMessageModel *)model
{
    AgoraChatTextMessageBody *body = (AgoraChatTextMessageBody *)model.emModel.body;
    self.textLabel.attributedText = [EMEmojiHelper convertStrings:body.text];
}

@end
