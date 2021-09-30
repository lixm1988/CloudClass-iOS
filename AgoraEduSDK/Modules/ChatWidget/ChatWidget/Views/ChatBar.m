//
//  ChatBar.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/5.
//

#import "ChatBar.h"
#import "UIImage+ChatExt.h"
#import "ChatWidget+Localizable.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <HyphenateChat/HyphenateChat.h>
#import "EmojiKeyboardView.h"


#define CONTAINVIEW_HEIGHT 40
#define SENDBUTTON_HEIGHT 26
#define SENDBUTTON_WIDTH 40
#define INPUT_WIDTH 120
#define EMOJIBUTTON_WIDTH 24

@interface ChatBar ()<InputingViewDelegate,UIImagePickerControllerDelegate,UITextFieldDelegate>
@property (nonatomic,strong) UIButton* emojiButton;
@property (nonatomic,strong) UIButton* imageButton;
@property (nonatomic,strong) UIButton* exitInputButton;
@property (nonatomic) CGRect oldframe;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
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
    //self.backgroundColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0];
    self.layer.borderColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0].CGColor;
    self.layer.borderWidth = 1;
    self.inputButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.inputButton setTitle:[ChatWidget LocalizedString:@"ChatPlaceholderText"] forState:UIControlStateNormal] ;
    self.inputButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.inputButton.backgroundColor = [UIColor clearColor];
    [self.inputButton setTitleColor:[UIColor colorWithRed:125/255.0 green:135/255.0 blue:152/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.inputButton addTarget:self action:@selector(InputAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.inputButton];
    self.inputButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.inputButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    self.emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.emojiButton setImage:[UIImage imageNamedFromBundle:@"icon_emoji"]
                      forState:UIControlStateNormal];
    [self.emojiButton setImage:[UIImage imageNamedFromBundle:@"icon_keyboard"]
                      forState:UIControlStateSelected];
    self.emojiButton.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.emojiButton];
    [self.emojiButton addTarget:self
                         action:@selector(emojiButtonAction)
               forControlEvents:UIControlEventTouchUpInside];
    
    self.imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.imageButton setImage:[UIImage imageNamedFromBundle:@"icon_image"]
                      forState:UIControlStateNormal];
    self.imageButton.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.imageButton];
    [self.imageButton addTarget:self
                         action:@selector(imageButtonAction)
               forControlEvents:UIControlEventTouchUpInside];
        
        UIWindow * window=[[[UIApplication sharedApplication] delegate] window];
        self.inputingView = [[InputingView alloc] initWithFrame:CGRectMake(0, 100, window.frame.size.width, 40)];
        self.inputingView.delegate = self;
        self.exitInputButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.exitInputButton.frame = window.frame;
        [self.exitInputButton addTarget:self action:@selector(ExitInputAction) forControlEvents:UIControlEventTouchUpInside];
        [window addSubview:self.exitInputButton];
        [window bringSubviewToFront:self.inputingView];
        [window addSubview:self.inputingView];
        self.inputingView.exitInputButton = self.exitInputButton;
        self.inputingView.hidden = YES;
        self.exitInputButton.hidden = YES;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    self.oldframe = self.frame;
    NSInteger imageWidth = 20;
    
    self.inputButton.frame = CGRectMake(10,0,self.bounds.size.width - EMOJIBUTTON_WIDTH*2 - 5,
                                               self.bounds.size.height);
    
    self.imageButton.frame = CGRectMake(self.bounds.size.width - EMOJIBUTTON_WIDTH-5,
                                            (self.bounds.size.height-imageWidth)/2,
                                        imageWidth,
                                        imageWidth);
    
    self.emojiButton.frame = CGRectMake(self.bounds.size.width - EMOJIBUTTON_WIDTH * 2-5,
                                        (self.bounds.size.height-imageWidth)/2,
                                        imageWidth,
                                        imageWidth);
}

- (void)ExitInputAction
{
    [self.inputingView.inputField resignFirstResponder];
    self.inputingView.hidden = YES;
    self.exitInputButton.hidden = YES;
}

- (void)InputAction
{
    self.inputingView.hidden = NO;
    self.exitInputButton.hidden = NO;
    if([self.inputingView.inputField isFirstResponder])
        [self.inputingView.inputField resignFirstResponder];
    [self.inputingView.inputField becomeFirstResponder];
}
- (void)emojiButtonAction
{
    [self InputAction];
    [self.inputingView.emojiButton setSelected:YES];
    [self.inputingView changeKeyBoardType];
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
        [self.inputButton setTitle:[ChatWidget LocalizedString:@"ChatAllMute"] forState:UIControlStateNormal];
        [self.inputButton setEnabled:NO];
        self.emojiButton.enabled = NO;
        self.imageButton.enabled = NO;
        
    }else{
        if(self.isMuted){
            [self.inputButton setTitle:[ChatWidget LocalizedString:@"ChatMuteText"] forState:UIControlStateNormal];
            [self.inputButton setEnabled:NO];
            self.emojiButton.enabled = NO;
            self.imageButton.enabled = NO;
        }else{
            [self.inputButton setTitle:[ChatWidget LocalizedString:@"ChatPlaceholderText"] forState:UIControlStateNormal];
            [self.inputButton setEnabled:YES];
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

#pragma mark - InputingViewDelegate
- (void)msgWillSend:(NSString *)aMsgText
{
    [self.delegate msgWillSend:aMsgText];
}

- (void)keyBoardDidHide:(NSString*)aText
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(aText.length > 0) {
            [self.inputButton setTitle:aText forState:UIControlStateNormal];
        }else{
            if(!self.isMuted && !self.isAllMuted)
                [self.inputButton setTitle:[ChatWidget LocalizedString:@"ChatPlaceholderText"] forState:UIControlStateNormal];
        }
    });
    
}

- (void)imageButtonDidClick
{
    [self imageButtonAction];
}
@end
