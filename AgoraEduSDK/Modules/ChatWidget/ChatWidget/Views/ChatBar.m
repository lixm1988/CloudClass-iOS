//
//  ChatBar.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/5.
//

#import "ChatBar.h"
#import "UIImage+ChatExt.h"
#import "InputingView.h"
#import "ChatWidget+Localizable.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <HyphenateChat/HyphenateChat.h>
#import "EmojiKeyboardView.h"


#define CONTAINVIEW_HEIGHT 40
#define SENDBUTTON_HEIGHT 26
#define SENDBUTTON_WIDTH 60
#define INPUT_WIDTH 120
#define EMOJIBUTTON_WIDTH 40

@interface ChatBar ()<InputingViewDelegate,UIImagePickerControllerDelegate,UITextFieldDelegate>
@property (nonatomic,strong) UITextField* inputField;
@property (nonatomic,strong) UIButton* emojiButton;
@property (nonatomic,strong) UIButton* imageButton;
@property (nonatomic,strong) UIButton* sendButton;
@property (nonatomic) CGRect oldframe;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic,strong) EmojiKeyboardView *emojiKeyBoardView;
@property (nonatomic,strong) UITapGestureRecognizer* resignRecognizer;
@end

@implementation ChatBar
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
    self.backgroundColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0];
    self.inputField = [[UITextField alloc] init];
    self.inputField.placeholder = [ChatWidget LocalizedString:@"ChatPlaceholderText"] ;
    self.inputField.backgroundColor = [UIColor clearColor];
    self.inputField.textColor = [UIColor colorWithRed:125/255.0 green:135/255.0 blue:152/255.0 alpha:1.0];
    self.inputField.returnKeyType = UIReturnKeySend;
    self.inputField.delegate = self;
    [self addSubview:self.inputField];
    self.inputField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    self.emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.emojiButton setImage:[UIImage imageNamedFromBundle:@"icon_emoji"]
                      forState:UIControlStateNormal];
    [self.emojiButton setImage:[UIImage imageNamedFromBundle:@"icon_keyboard"]
                      forState:UIControlStateSelected];
    self.emojiButton.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:self.emojiButton];
    [self.emojiButton addTarget:self
                         action:@selector(emojiButtonAction)
               forControlEvents:UIControlEventTouchUpInside];
    
    self.imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.imageButton setImage:[UIImage imageNamedFromBundle:@"icon-image"]
                      forState:UIControlStateNormal];
    self.imageButton.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.imageButton];
    [self.imageButton addTarget:self
                         action:@selector(imageButtonAction)
               forControlEvents:UIControlEventTouchUpInside];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendButton setTitle:[ChatWidget LocalizedString:@"ChatSendText"]
                     forState:UIControlStateNormal];
    [self addSubview:self.sendButton];
    self.sendButton.backgroundColor = [UIColor colorWithRed:53/255.0 green:123/255.0 blue:246/255.0 alpha:1.0];
    self.sendButton.layer.cornerRadius = 16;
    [self.sendButton setTitleColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.sendButton addTarget:self
                        action:@selector(sendButtonAction)
              forControlEvents:UIControlEventTouchUpInside];
    
    self.emojiKeyBoardView = [[EmojiKeyboardView alloc] initWithFrame:CGRectMake(0,0,self.bounds.size.width,176)];
    self.emojiKeyBoardView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    self.oldframe = self.frame;
    
    self.inputField.frame = CGRectMake(10,self.bounds.size.height - CONTAINVIEW_HEIGHT,self.bounds.size.width - SENDBUTTON_WIDTH - 20,
                                           CONTAINVIEW_HEIGHT);
    
    self.emojiButton.frame = CGRectMake(14,
                                        10,
                                        20,
                                        20);
    
    self.imageButton.frame = CGRectMake(46,
                                        10,
                                        20,
                                        20);
    
    self.sendButton.frame = CGRectMake(self.bounds.size.width - SENDBUTTON_WIDTH-8,
                                       self.bounds.size.height-SENDBUTTON_HEIGHT-6,
                                       SENDBUTTON_WIDTH,
                                       SENDBUTTON_HEIGHT);
}

- (void)emojiButtonAction
{
    [self.inputField becomeFirstResponder];
    [self.emojiButton setSelected:!self.emojiButton.isSelected];
    [self changeKeyBoardType];
}

- (void)changeKeyBoardType
{
    if(self.emojiButton.isSelected) {
            self.inputField.inputView = self.emojiKeyBoardView;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.inputField reloadInputViews];
            });
        }else{
            self.inputField.inputView = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.inputField reloadInputViews];
            });
        }
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

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendButtonAction];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.window becomeFirstResponder];
    [self.window addGestureRecognizer:self.resignRecognizer];
}

// 失去焦点
- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self.window removeGestureRecognizer:self.resignRecognizer];
}

- (void)touchOutside:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.window resignFirstResponder];
        [self.window endEditing:YES];
    }
}

- (void)sendButtonAction
{
    NSString* str = self.inputField.text;
    if(str) {
        [self.delegate msgWillSend:str];
    }
    self.inputField.text = @"";
    [self.inputField resignFirstResponder];
}

- (void)imageButtonAction
{
    [self pickImageAndSend];
}

- (UIImagePickerController *)imagePicker
{
    if (_imagePicker == nil) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.modalPresentationStyle = UIModalPresentationOverFullScreen;
        _imagePicker.delegate = self;
    }
    
    return _imagePicker;
}

- (void)pickImageAndSend
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case PHAuthorizationStatusAuthorized: //已获取权限
                {
                    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    self.imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
                    UIViewController *viewController = [[self class] dc_findCurrentShowingViewController];
                    [viewController presentViewController:self.imagePicker animated:YES completion:nil];
                }
                    break;
                case PHAuthorizationStatusDenied: //用户已经明确否认了这一照片数据的应用程序访问
                    
                    break;
                case PHAuthorizationStatusRestricted://此应用程序没有被授权访问的照片数据。可能是家长控制权限
                    
                    break;
                    
                default:
                    
                    break;
            }
        });
    }];
}

#pragma mark - setter
- (void)setIsMuted:(BOOL)isMuted
{
    _isMuted = isMuted;
    [self updateMuteState];
}

- (void)setIsAllMuted:(BOOL)isAllMuted
{
    _isAllMuted = isAllMuted;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMuteState];
    });
}

- (void)updateMuteState
{
    if(self.isAllMuted) {
        self.inputField.text = [ChatWidget LocalizedString:@"ChatAllMute"];
        [self.inputField setEnabled:NO];
        self.emojiButton.enabled = NO;
        self.imageButton.enabled = NO;
        
    }else{
        if(self.isMuted){
            self.inputField.text = [ChatWidget LocalizedString:@"ChatMute"];
            [self.inputField setEnabled:NO];
            self.emojiButton.enabled = NO;
            self.imageButton.enabled = NO;
        }else{
            self.inputField.text = @"";
            [self.inputField setEnabled:YES];
            self.emojiButton.enabled = YES;
            self.imageButton.enabled = YES;
        }
    }
}

// 获取当前显示的 UIViewController
+ (UIViewController *)dc_findCurrentShowingViewController {
    //获得当前活动窗口的根视图
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *currentShowingVC = [self findCurrentShowingViewControllerFrom:vc];
    return currentShowingVC;
}
+ (UIViewController *)findCurrentShowingViewControllerFrom:(UIViewController *)vc
{
    // 递归方法 Recursive method
    UIViewController *currentShowingVC;
    if ([vc presentedViewController]) {
        // 当前视图是被presented出来的
        UIViewController *nextRootVC = [vc presentedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];

    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        UIViewController *nextRootVC = [(UITabBarController *)vc selectedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];

    } else if ([vc isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        UIViewController *nextRootVC = [(UINavigationController *)vc visibleViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];

    } else {
        // 根视图为非导航类
        currentShowingVC = vc;
    }

    return currentShowingVC;
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if(image) {
        NSData *data = UIImageJPEGRepresentation(image, 1);
        [self.delegate imageDataWillSend:data];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CustomKeyBoardDelegate

- (void)emojiItemDidClicked:(NSString *)item{
    self.inputField.text = [self.inputField.text stringByAppendingString:item];
}

- (void)emojiDidDelete
{
    if ([self.inputField.text length] > 0) {
        NSRange range = [self.inputField.text rangeOfComposedCharacterSequenceAtIndex:self.inputField.text.length-1];
        self.inputField.text = [self.inputField.text substringToIndex:range.location];
    }
}

#pragma mark - 键盘显示
- (void)keyboardWillChangeFrame:(NSNotification *)notification{
        //取出键盘动画的时间(根据userInfo的key----UIKeyboardAnimationDurationUserInfoKey)
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    //self.emojiKeyBoardView.frame = keyboardFrame;
    //执行动画
    [UIView animateWithDuration:duration animations:^{
        UIWindow * window=[[[UIApplication sharedApplication] delegate] window];
        CGRect rect=[self convertRect: self.bounds toView:window];    //获取控件view的相对坐标
        {
            CGRect lastframe = self.frame;
            self.frame = CGRectMake(lastframe.origin.x, lastframe.origin.y - (rect.origin.y - keyboardFrame.origin.y) - lastframe.size.height, lastframe.size.width, lastframe.size.height);
            
        }
        
    }];
}


#pragma mark --键盘收回
- (void)keyboardDidHide:(NSNotification *)notification{
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:duration animations:^{
        self.frame = self.oldframe;
    }];
}
@end
