//
//  AnnouncementView.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/3.
//

#import "AnnouncementView.h"
#import "UIImage+ChatExt.h"
#import <Masonry/Masonry.h>
#import "ChatWidget+Localizable.h"
#import "ChatWidgetDefine.h"
#import <AgoraUIEduBaseViews/AgoraUIEduBaseViews-Swift.h>

@interface NilAnnouncementView ()
@property (nonatomic,strong) UIImageView* nilAnnouncementImageView;
@property (nonatomic,strong) UILabel* nilAnnouncementLable;
@property (nonatomic,strong) UIButton* publishButton;
@property (nonatomic) NSInteger role;
@property (nonatomic,weak) AnnouncementView*parantView;
@end

@implementation NilAnnouncementView

- (instancetype)initWithRole:(NSInteger)role
{
    self = [super init];
    if(self) {
        self.role = role;
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews
{
    self.nilAnnouncementImageView = [[UIImageView alloc] init];
    self.nilAnnouncementImageView.image = [UIImage imageNamedFromBundle:@"icon_nil"];
    [self addSubview:self.nilAnnouncementImageView];
    [self.nilAnnouncementImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self);
        make.width.equalTo(@80);
        make.height.equalTo(@72);
    }];
    
    self.nilAnnouncementLable = [[UILabel alloc] init];
    self.nilAnnouncementLable.text = [ChatWidget LocalizedString:@"ChatNoAnnouncement"];
    self.nilAnnouncementLable.textAlignment = NSTextAlignmentCenter;
    self.nilAnnouncementLable.font = [UIFont systemFontOfSize:12];
    [self addSubview:self.nilAnnouncementLable];
    
    if(ROLE_IS_TEACHER(self.role)) {
        [self.nilAnnouncementLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self);
            make.left.equalTo(self);
            make.height.equalTo(@20);
        }];
        [self addSubview:self.publishButton];
        [self.publishButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.nilAnnouncementLable);
            make.left.equalTo(self.nilAnnouncementLable.mas_right).offset(3);
            make.height.equalTo(self.nilAnnouncementLable);
        }];
    }else{
        [self.nilAnnouncementLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self);
            make.centerX.equalTo(self);
            make.height.equalTo(@20);
        }];
    }
}

- (UIButton*)publishButton
{
    if(!_publishButton) {
        _publishButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_publishButton setTitle:[ChatWidget LocalizedString:@"ChatPublish"] forState:UIControlStateNormal];
        _publishButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_publishButton addTarget:self action:@selector(publishAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _publishButton;
}

- (void)publishAction
{
    [self.parantView performSelector:@selector(setEdit:) withObject:[NSNumber numberWithBool:YES]];
}

@end

@interface EditAnnouncementView ()<UITextViewDelegate>
@property (nonatomic,strong) NSString* announcement;
@property (nonatomic,strong) UIButton* saveButton;
@property (nonatomic,strong) UIButton* cancelButton;
@property (nonatomic,strong) UITextView* announcementText;
@property (nonatomic,strong) UILabel* errorLable;
@property (nonatomic,strong) UILabel* countLable;
@property (nonatomic,weak) AnnouncementView* parantView;
@property (nonatomic,strong) UITapGestureRecognizer* resignRecognizer;
@end

@implementation EditAnnouncementView
- (instancetype)initWithAnnouncement:(NSString*)announcement
{
    self = [super init];
    if(self) {
        self.announcement = announcement;
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews
{
    [self addSubview:self.saveButton];
    [self addSubview:self.cancelButton];
    [self addSubview:self.announcementText];
    [self addSubview:self.errorLable];
    [self addSubview:self.countLable];
    [self.announcementText mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(14);
            make.right.equalTo(self).offset(-14);
            make.top.equalTo(self).offset(14);
            make.height.equalTo(@130);
    }];
    [self.errorLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.announcementText);
        make.height.equalTo(@18);
        make.top.equalTo(self.announcementText.mas_bottom).offset(2);
    }];
    [self.countLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.announcementText);
        make.height.equalTo(@18);
        make.top.equalTo(self.announcementText.mas_bottom).offset(2);
    }];
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self).with.multipliedBy(1.5);
        make.width.equalTo(@60);
        make.height.equalTo(@24);
        make.top.equalTo(self.errorLable.mas_bottom).offset(5);
    }];
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self).with.multipliedBy(0.5);
        make.width.equalTo(@60);
        make.height.equalTo(@24);
        make.top.equalTo(self.errorLable.mas_bottom).offset(5);
    }];
    self.errorLable.hidden = YES;
}

- (UILabel*)errorLable
{
    if(!_errorLable) {
        _errorLable = [[UILabel alloc] init];
        _errorLable.font = [UIFont systemFontOfSize:12];
        _errorLable.textColor = [UIColor colorWithRed:240/255.0 green:76/255.0 blue:54/255.0 alpha:1.0];
        _errorLable.textAlignment = NSTextAlignmentLeft;
        _errorLable.text = @"Exceed 500";
    }
    return _errorLable;
}

- (UILabel*)countLable
{
    if(!_countLable) {
        _countLable = [[UILabel alloc] init];
        _countLable.font = [UIFont systemFontOfSize:12];
        _countLable.textColor = [UIColor colorWithRed:125/255.0 green:135/255.0 blue:152/255.0 alpha:1.0];
        _countLable.textAlignment = NSTextAlignmentRight;
        _countLable.text = @"0/500";
    }
    return _countLable;
}

- (UITextView*)announcementText
{
    if(!_announcementText) {
        _announcementText = [[UITextView alloc] init];
        _announcementText.text = self.announcement;
        _announcementText.textContainerInset = UIEdgeInsetsMake(10, 10, 0, 10);
        _announcementText.textColor = [UIColor colorWithRed:25/255.0 green:25/255.0 blue:25/255.0 alpha:1.0];
        _announcementText.layer.borderWidth = 1;
        _announcementText.layer.cornerRadius = 4;
        _announcementText.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
        _announcementText.delegate = self;
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 5;
        self.announcementText.typingAttributes = @{
            NSFontAttributeName:[UIFont systemFontOfSize:12],
            NSParagraphStyleAttributeName:paragraphStyle
            };
    }
    return _announcementText;
}

- (UIButton*)saveButton
{
    if(!_saveButton) {
        _saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_saveButton setTitle:[ChatWidget LocalizedString:@"ChatSave"] forState:UIControlStateNormal];
        _saveButton.layer.borderColor = [UIColor blackColor].CGColor;
        _saveButton.layer.cornerRadius = 12;
        _saveButton.layer.backgroundColor = [UIColor colorWithRed:53/255.0 green:123/255.0 blue:246/255.0 alpha:1.0].CGColor;
        [_saveButton setTitleColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
        _saveButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_saveButton addTarget:self action:@selector(saveAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveButton;
}

- (UIButton*)cancelButton
{
    if(!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _cancelButton.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
        _cancelButton.layer.borderWidth = 1;
        _cancelButton.layer.cornerRadius = 12;
        [_cancelButton setTitleColor:[UIColor colorWithRed:103/255.0 green:115/255.0 blue:134/255.0 alpha:1.0] forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_cancelButton setTitle:[ChatWidget LocalizedString:@"ChatCancel"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (UIGestureRecognizer*)resignRecognizer
{
    if(!_resignRecognizer) {
        _resignRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchOutside:)];
        _resignRecognizer.cancelsTouchesInView = NO;
        _resignRecognizer.enabled = YES;
        _resignRecognizer.delegate = self;
    }
    return _resignRecognizer;
}

- (void)saveAction
{
    [self.parantView performSelector:@selector(setEdit:) withObject:[NSNumber numberWithBool:NO]];
    if(![self.announcementText.text isEqualToString:self.announcement]) {
        // 更新公告
        [self.parantView.delegate PublishAnnouncement:self.announcementText.text];
    }
}

- (void)cancelAction
{
    [self.parantView performSelector:@selector(setEdit:) withObject:[NSNumber numberWithBool:NO]];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    NSInteger count = textView.text.length;
    self.errorLable.hidden = count <= 500;
    self.countLable.text = [NSString stringWithFormat:@"%d/500",count];
    self.countLable.textColor = count <= 500?[UIColor colorWithRed:125/255.0 green:135/255.0 blue:152/255.0 alpha:1.0]:[UIColor colorWithRed:240/255.0 green:76/255.0 blue:54/255.0 alpha:1.0];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self.window becomeFirstResponder];
    [self.window addGestureRecognizer:self.resignRecognizer];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.window removeGestureRecognizer:self.resignRecognizer];
}

- (void)touchOutside:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.window resignFirstResponder];
        [self.window endEditing:YES];
    }
}

@end

@interface AnnouncementView ()
@property (nonatomic,strong) NilAnnouncementView* nilAnnouncementView;
@property (nonatomic,strong) UITextView* announcementText;
@property (nonatomic,strong) UIButton* updateButton;
@property (nonatomic,strong) UIButton* removeButton;
@property (nonatomic,strong) EditAnnouncementView* editView;
@end

@implementation AnnouncementView

- (instancetype)initWithFrame:(CGRect)frame role:(NSInteger)role
{
    self = [super initWithFrame:frame];
    if(self) {
        self.role = role;
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews
{
    self.backgroundColor = [UIColor whiteColor];
    self.nilAnnouncementView = [[NilAnnouncementView alloc] initWithRole:self.role];
    self.nilAnnouncementView.parantView = self;
    [self addSubview:self.nilAnnouncementView];
    [self.nilAnnouncementView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@100);
        make.center.equalTo(self);
    }];
    
    if(ROLE_IS_TEACHER(self.role)) {
        [self addSubview:self.updateButton];
        [self addSubview:self.removeButton];
        [self.removeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).with.offset(-5);
            make.top.equalTo(self);
            make.width.height.equalTo(@20);
        }];
        [self.updateButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.removeButton.mas_left);
            make.top.equalTo(self.removeButton);
            make.width.height.equalTo(@20);
        }];
        [self addSubview:self.editView];
        [self.editView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.edges.equalTo(self);
        }];
        self.editView.hidden = YES;
    }
    
    self.announcementText = [[UITextView alloc] init];
    [self.announcementText setEditable:NO];
    [self addSubview:self.announcementText];
    self.announcementText.textColor = [UIColor colorWithRed:25/255.0 green:25/255.0 blue:25/255.0 alpha:1.0];
    //self.announcementText.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    //[self.announcementText sizeToFit];
    //self.announcementText.numberOfLines = 0;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineSpacing = 5;
    self.announcementText.typingAttributes = @{
        NSFontAttributeName:[UIFont systemFontOfSize:12],
        NSParagraphStyleAttributeName:paragraphStyle
        };
    self.announcementText.textAlignment = NSTextAlignmentLeft;
    [self.announcementText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self).with.offset(-40);
        make.width.equalTo(self).with.offset(-14);
        make.centerX.equalTo(self);
        make.top.equalTo(@20);
    }];
    
    self.announcement = @"";
}

- (void)setAnnouncement:(NSString *)announcement
{
    _announcement = announcement;
    [self.announcementText setText:announcement];
    if(ROLE_IS_TEACHER(self.role)) {
        self.updateButton.hidden = _announcement.length == 0;
        self.removeButton.hidden = _announcement.length == 0;
    }
    self.announcementText.hidden = _announcement.length == 0;
    self.nilAnnouncementView.hidden = _announcement.length > 0;
}

- (void)setRole:(NSInteger)role
{
    _role = role;
}

- (UIButton*)updateButton
{
    if(!_updateButton) {
        _updateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_updateButton setImage:[UIImage imageNamedFromBundle:@"icon_update"] forState:UIControlStateNormal];
        [_updateButton addTarget:self action:@selector(updateAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _updateButton;
}

- (UIButton*)removeButton
{
    if(!_removeButton) {
        _removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_removeButton setImage:[UIImage imageNamedFromBundle:@"icon_remove"] forState:UIControlStateNormal];
        _removeButton.contentMode = UIViewContentModeScaleAspectFit;
        [_removeButton addTarget:self action:@selector(removeAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _removeButton;
}

- (EditAnnouncementView*)editView
{
    if(!_editView) {
        _editView = [[EditAnnouncementView alloc] initWithAnnouncement:self.announcement];
        _editView.parantView = self;
    }
    return _editView;
}


- (void)updateAction
{
    [self setEdit:@YES];
}

- (void)removeAction
{
    __weak typeof(self) weakself = self;
    AgoraAlertLabelModel* cancelLable = [[AgoraAlertLabelModel alloc] init];
    cancelLable.text = [ChatWidget LocalizedString:@"ChatCancel"];
    AgoraAlertButtonModel* cancelButton = [[AgoraAlertButtonModel alloc] init];
    cancelButton.titleLabel = cancelLable;
    
    AgoraAlertLabelModel* sureLable = [[AgoraAlertLabelModel alloc] init];
    sureLable.text = [ChatWidget LocalizedString:@"ChatOK"];
    AgoraAlertButtonModel* sureButton = [[AgoraAlertButtonModel alloc] init];
    sureButton.titleLabel = sureLable;
    sureButton.tapActionBlock = ^(NSInteger index) {
        [weakself.delegate PublishAnnouncement:@""];
    };
    [AgoraUtils showAlertWithImageModel:nil title:[ChatWidget LocalizedString:@"ChatRemoveAnnouncementTitle"] message:[ChatWidget LocalizedString:@"ChatRemoveAnnouncementText"] btnModels:@[cancelButton,sureButton]];
    
}

- (void)setEdit:(NSNumber*)isEdit
{
    BOOL bEdit = [isEdit boolValue];
    self.editView.hidden = !bEdit;
    if(bEdit) {
        self.editView.announcement = self.announcement;
        self.editView.announcementText.text = self.announcement;
        self.nilAnnouncementView.hidden = YES;
        self.announcementText.hidden = YES;
        self.updateButton.hidden = YES;
        self.removeButton.hidden = YES;
    }else{
        self.nilAnnouncementView.hidden = self.announcement.length > 0;
        self.announcementText.hidden = self.announcement.length == 0;
        self.announcementText.layer.borderWidth = 0;
        self.updateButton.hidden = self.announcement.length == 0;
        self.removeButton.hidden = self.announcement.length == 0;
    }
}

@end
