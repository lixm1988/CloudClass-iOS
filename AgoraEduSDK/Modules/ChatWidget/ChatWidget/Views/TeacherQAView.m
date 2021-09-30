//
//  TeacherQAView.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/9/15.
//

#import "TeacherQAView.h"
#import "QaUserModel.h"
#import <Masonry/Masonry.h>

@interface TeacherQAView ()
@property (nonatomic,strong) UIButton* backButton;
@property (nonatomic,strong) UILabel* lable;
@end

@implementation TeacherQAView

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
    [self addSubview:self.backButton];
    [self addSubview:self.qaView];
    [self bringSubviewToFront:self.backButton];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(5);
        make.width.equalTo(@52);
        make.height.equalTo(@22);
        make.left.equalTo(self).offset(-22);
    }];
    [self.qaView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self);
        make.top.equalTo(self);
    }];
}

- (void)resetMsgs:(NSMutableArray *)msgArray
{
    [self.qaView resetMsgs];
    [self addMsgs:msgArray];
}

- (void)addMsgs:(NSMutableArray*)msgArray
{
    [self.qaView updateMsgs:msgArray];
}

- (void)backAction
{
    [self removeFromSuperview];
    if(self.delegate && [self.delegate respondsToSelector:@selector(teacherQAViewDidClose)]) {
        [self.delegate teacherQAViewDidClose];
    }
}

#pragma mark - getter
- (UIButton*)backButton
{
    if(!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_backButton setTitle:@"<" forState:UIControlStateNormal];
        [_backButton setTitleColor:[UIColor colorWithRed:0x7b/0xff green:0x88/0xff blue:0xa0/0xff alpha:1.0]  forState:UIControlStateNormal];
        _backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _backButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 11);
        _backButton.backgroundColor = [UIColor whiteColor];
        [_backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        _backButton.layer.cornerRadius = 11;
        _backButton.layer.borderWidth = 1;
        _backButton.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
    }
    return _backButton;
}

- (QAView*)qaView
{
    if(!_qaView) {
        _qaView = [[QAView alloc] init];
    }
    return _qaView;
}
@end
