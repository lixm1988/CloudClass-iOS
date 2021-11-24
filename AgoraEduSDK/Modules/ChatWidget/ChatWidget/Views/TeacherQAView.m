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
@property (nonatomic,strong) UIView* backButton;
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
    [self.qaView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self);
        make.top.equalTo(@22);
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
- (UIView*)backButton
{
    if(!_backButton) {
//        _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
//        [_backButton setTitle:@"<" forState:UIControlStateNormal];
//        [_backButton setTitleColor:[UIColor colorWithRed:0x7b/0xff green:0x88/0xff blue:0xa0/0xff alpha:1.0]  forState:UIControlStateNormal];
//        _backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
//        _backButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 11);
//        _backButton.backgroundColor = [UIColor whiteColor];
//        [_backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
//        _backButton.layer.cornerRadius = 11;
//        _backButton.layer.borderWidth = 1;
//        _backButton.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
        UIView *view2=[[UIView alloc] initWithFrame:CGRectMake(0, 5, 30, 20)];
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:view2.bounds byRoundingCorners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(10, 10)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = view2.bounds;
        maskLayer.path = maskPath.CGPath;
        maskLayer.fillColor = [UIColor whiteColor].CGColor;
        maskLayer.lineWidth = 2.0;
        maskLayer.strokeColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
        [view2.layer addSublayer:maskLayer];
        UILabel* title = [[UILabel alloc] init];
        title.text = @"<";
        [view2 addSubview:title];
        title.textAlignment = NSTextAlignmentCenter;
        title.frame = CGRectMake(0, 0, 30, 20);
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchBackButton)];
        view2.userInteractionEnabled = YES;
        [view2 addGestureRecognizer:tapGesture];
        _backButton = view2;
    }
    return _backButton;
}

- (void)touchBackButton
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(backAction) object:nil];
    [self performSelector:@selector(backAction) withObject:nil afterDelay:0.1];
}

- (QAView*)qaView
{
    if(!_qaView) {
        _qaView = [[QAView alloc] init];
    }
    return _qaView;
}
@end
