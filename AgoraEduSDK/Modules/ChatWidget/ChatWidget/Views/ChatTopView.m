//
//  ChatTopView.m
//  AgoraEducation
//
//  Created by lixiaoming on 2021/6/21.
//

#import "ChatTopView.h"
#import "UIImage+ChatExt.h"
#import <Masonry/Masonry.h>
#import "ChatWidget+Localizable.h"
const static NSInteger TAG_BASE = 1000;
#define BUTTON_WIDTH 60
#define PERCENT 0.25
#define BUTTON_HEIGHT 40

@interface ChatTopView ()<UIScrollViewDelegate>
@property (nonatomic,strong) UIButton* chatButton;
@property (nonatomic,strong) UIButton* hideButton;
@property (nonatomic,strong) UIButton* qaButton;
@property (nonatomic,strong) UIButton* membersButton;
@property (nonatomic,strong) UIButton* announcementButton;
@property (nonatomic,strong) UIView* selLine;
@property (nonatomic) NSUInteger tabCount;
@property (nonatomic,strong) UIColor* selTitleColor;
@property (nonatomic,strong) UIColor* unselTitleColor;
@property (nonatomic,strong) UIScrollView* scrollView;
@end

@implementation ChatTopView

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
    self.backgroundColor = [UIColor whiteColor];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
    self.layer.cornerRadius = 5;
    
    int width = 16;
    self.hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.hideButton.tag = TAG_BASE + 2;
    [self.hideButton setImage:[UIImage imageNamedFromBundle:@"icon_hide"] forState:UIControlStateNormal];
    [self.hideButton addTarget:self action:@selector(hideAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.hideButton];
    [self.hideButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).with.offset(-14);
        make.centerY.equalTo(self);
        make.height.equalTo(@(width));
        make.width.equalTo(@(width));
    }];
    
    [self addSubview:self.scrollView];
    self.scrollView.frame = CGRectZero;
    self.scrollView.contentSize = CGSizeMake(BUTTON_WIDTH*4, BUTTON_HEIGHT);
//    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(self);
//        make.right.equalTo(self.hideButton.mas_left);
//        make.height.equalTo(self);
//        make.top.equalTo(self);
//    }];
    
    self.chatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.chatButton setTitle:[ChatWidget LocalizedString:@"ChatText"] forState:UIControlStateNormal];
    [self.chatButton setTitleColor:self.selTitleColor forState:UIControlStateNormal];
    self.chatButton.tag = TAG_BASE;
    self.chatButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.chatButton addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.chatButton];
//    [self.chatButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(@(BUTTON_WIDTH*0));
//        make.top.equalTo(@0);
//        make.height.equalTo(self.scrollView);
//        make.width.equalTo(@(BUTTON_WIDTH));
//    }];
    //self.chatButton.contentEdgeInsets = UIEdgeInsetsMake(0,10, 0, 0);

    self.chatBadgeView = [[CustomBadgeView alloc] init];
    [self.scrollView addSubview:self.chatBadgeView];
    self.chatBadgeView.hidden = YES;
//    [self.chatBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self).offset(10);
//        make.width.height.equalTo(@(self.chatBadgeView.badgeSize));
//        make.centerX.equalTo(self.chatButton).offset(20);
//    }];
    
    self.qaButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.qaButton setTitle:[ChatWidget LocalizedString:@"ChatQA"] forState:UIControlStateNormal];
    [self.qaButton setTitleColor:self.unselTitleColor forState:UIControlStateNormal];
    self.qaButton.tag = TAG_BASE + 1;
    [self.qaButton addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.qaButton];
//    [self.qaButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(@(BUTTON_WIDTH*1));
//        make.top.equalTo(@0);
//        make.height.equalTo(self.scrollView);
//        make.width.equalTo(@(BUTTON_WIDTH));
//    }];
    //self.qaButton.contentEdgeInsets = UIEdgeInsetsMake(0,10, 0, 0);
    
    self.qaBadgeView = [[CustomBadgeView alloc] init];
    [self.scrollView addSubview:self.qaBadgeView];
    self.qaBadgeView.hidden = YES;
//    [self.qaBadgeView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self).offset(10);
//        make.width.height.equalTo(@(self.chatBadgeView.badgeSize));
//        make.centerX.equalTo(self.qaButton).offset(20);
//    }];
    
    self.membersButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.membersButton setTitle:[ChatWidget LocalizedString:@"ChatMembers"] forState:UIControlStateNormal];
    [self.membersButton setTitleColor:self.unselTitleColor forState:UIControlStateNormal];
    self.membersButton.tag = TAG_BASE + 2;
    [self.membersButton addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.membersButton];
//    [self.membersButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(@(BUTTON_WIDTH*2));
//        make.top.equalTo(@0);
//        make.height.equalTo(self.scrollView);
//        make.width.equalTo(@(BUTTON_WIDTH));
//    }];
    //self.membersButton.contentEdgeInsets = UIEdgeInsetsMake(0,10, 0, 0);
    
    self.announcementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.announcementButton setTitle:[ChatWidget LocalizedString:@"ChatAnnouncement"] forState:UIControlStateNormal];
    self.announcementButton.tag = TAG_BASE + 3;
    [self.announcementButton addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.announcementButton setTitleColor:[UIColor colorWithRed:123/255.0 green:136/255.0 blue:160/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.scrollView addSubview:self.announcementButton];
//    [self.announcementButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(@(BUTTON_WIDTH*3));
//        make.top.equalTo(@0);
//        make.height.equalTo(self.scrollView);
//        make.width.equalTo(@(BUTTON_WIDTH));
//    }];
    self.announcementbadgeView = [[CustomBadgeView alloc] init];
    [self.scrollView addSubview:self.announcementbadgeView];
    self.announcementbadgeView.hidden = YES;
    
    self.selLine = [[UIView alloc] init];
    self.selLine.backgroundColor = [UIColor colorWithRed:53/255.0 green:123/255.0 blue:246/255.0 alpha:1.0];
    [self.scrollView addSubview:self.selLine];
    [self.scrollView bringSubviewToFront:self.selLine];
    
//    [self.selLine mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(self.scrollView);
//        make.bottom.equalTo(self.scrollView);
//        make.height.equalTo(@12);
//        make.width.equalTo(@(BUTTON_WIDTH*4));
//    }];
    
    self.currentTab = 0;
    [self noticeSelectedTab];
}

- (void)layoutSubviews
{
    self.scrollView.frame = CGRectMake(0, 0, self.bounds.size.width - 40, BUTTON_HEIGHT);
    self.chatButton.frame = CGRectMake(0, 0, BUTTON_WIDTH, BUTTON_HEIGHT-2);
    self.qaButton.frame = CGRectMake(BUTTON_WIDTH, 0, BUTTON_WIDTH, BUTTON_HEIGHT-2);
    self.membersButton.frame = CGRectMake(BUTTON_WIDTH*2, 0, BUTTON_WIDTH, BUTTON_HEIGHT-2);
    self.announcementButton.frame = CGRectMake(BUTTON_WIDTH*3, 0, BUTTON_WIDTH, BUTTON_HEIGHT-2);
    self.selLine.frame = CGRectMake(0, BUTTON_HEIGHT-9, BUTTON_WIDTH, 9);
    self.chatBadgeView.frame = CGRectMake(50, 10, 8, 8);
    self.qaBadgeView.frame = CGRectMake(BUTTON_WIDTH + 50, 10, 8, 8);
    self.announcementbadgeView.frame = CGRectMake(BUTTON_WIDTH*3 + 50, 10, 8, 8);
}

- (UIScrollView*)scrollView
{
    if(!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (NSUInteger)tabCount
{
    return 4;
}

- (void)clickAction:(UIButton*)button
{
    self.currentTab = button.tag - TAG_BASE;
}

- (void)hideAction
{
    if(self.delegate) {
        [self.delegate chatTopViewDidClickHide];
    }
}

- (UIColor*)selTitleColor
{
    return [UIColor colorWithRed:25/255.0 green:25/255.0 blue:25/255.0 alpha:1.0];
}

- (UIColor*)unselTitleColor
{
    return [UIColor colorWithRed:123/255.0 green:136/255.0 blue:160/255.0 alpha:1.0];
}

- (void)setSelectButton:(UIButton*)button
{
    CGRect frame = CGRectMake(BUTTON_WIDTH*self.currentTab, BUTTON_HEIGHT-9, button.bounds.size.width, 9);
    self.selLine.frame = frame;
    [self.chatButton setTitleColor:button == self.chatButton?self.selTitleColor:self.unselTitleColor forState:UIControlStateNormal];
    [self.qaButton setTitleColor:button == self.qaButton?self.selTitleColor:self.unselTitleColor forState:UIControlStateNormal];
    [self.membersButton setTitleColor:button == self.membersButton?self.selTitleColor:self.unselTitleColor forState:UIControlStateNormal];
    [self.announcementButton setTitleColor:button == self.announcementButton?self.selTitleColor:self.unselTitleColor forState:UIControlStateNormal];
}

- (void)setCurrentTab:(NSInteger)currentTab
{
    if(_currentTab != currentTab) {
        _currentTab = currentTab;
        switch (currentTab) {
            case 0:
                [self setSelectButton:self.chatButton];
                self.isShowRedNotice = NO;
                break;
            case 1:
                [self setSelectButton:self.qaButton];
                self.isShowQARedNotice = NO;
                break;
            case 2:
                [self setSelectButton:self.membersButton];
                break;
            case 3:
                [self setSelectButton:self.announcementButton];
                self.isShowAnnouncementRedNotice = NO;
                break;
            default:
                break;
        }
        [self noticeSelectedTab];
    }
}

- (void)noticeSelectedTab
{
    if(self.delegate) {
        [self.delegate chatTopViewDidSelectedChanged:self.currentTab];
    }
}

- (void)setIsShowRedNotice:(BOOL)isShowRedNotice
{
    _isShowRedNotice = isShowRedNotice;
    if(isShowRedNotice){
        self.chatBadgeView.hidden = NO;
    }else{
        self.chatBadgeView.hidden = YES;
    }
}

- (void)setIsShowQARedNotice:(BOOL)isShowQARedNotice
{
    _isShowQARedNotice = isShowQARedNotice;
    if(isShowQARedNotice){
        self.qaBadgeView.hidden = NO;
    }else{
        self.qaBadgeView.hidden = YES;
    }
}

- (void)setIsShowAnnouncementRedNotice:(BOOL)isShowAnnouncementRedNotice
{
    _isShowAnnouncementRedNotice = isShowAnnouncementRedNotice;
    if(isShowAnnouncementRedNotice){
        self.announcementbadgeView.hidden = NO;
    }else{
        self.announcementbadgeView.hidden = YES;
    }
}

@end
