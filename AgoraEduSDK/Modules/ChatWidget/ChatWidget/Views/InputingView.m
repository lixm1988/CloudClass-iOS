//
//  InputingView.m
//  ChatWidget
//
//  Created by lixiaoming on 2021/7/7.
//

#import "InputingView.h"
#import "EmojiKeyboardView.h"
#import "UIImage+ChatExt.h"
#import "ChatWidget+Localizable.h"
#import "EMEmojiHelper.h"
#import "EmojiTextAttachment.h"
#import "UITextView+Placeholder.h"

#define CONTAINVIEW_HEIGHT 40
#define SENDBUTTON_HEIGHT 30
#define SENDBUTTON_WIDTH 60
#define INPUT_WIDTH 120
#define EMOJIBUTTON_WIDTH 30
#define GAP 60

@interface InputingView ()<UITextViewDelegate,EmojiKeyboardDelegate>
@property (nonatomic,strong) EmojiKeyboardView *emojiKeyBoardView;
@property (nonatomic,strong) UIButton* imageButton;
@end

@implementation InputingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        [self setupSubViews];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupSubViews
{
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendButton setTitle:[ChatWidget LocalizedString:@"ChatSendText"]
                     forState:UIControlStateNormal];
    [self addSubview:self.sendButton];
    self.sendButton.backgroundColor = [UIColor colorWithRed:53/255.0 green:123/255.0 blue:246/255.0 alpha:1.0];
    self.sendButton.layer.cornerRadius = 16;
    [self.sendButton setTitleColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
    self.sendButton.frame = CGRectMake(self.bounds.size.width - SENDBUTTON_WIDTH-GAP,
                                       CONTAINVIEW_HEIGHT-SENDBUTTON_HEIGHT-5,
                                       SENDBUTTON_WIDTH,
                                       SENDBUTTON_HEIGHT);
    [self.sendButton addTarget:self
                        action:@selector(sendButtonAction)
              forControlEvents:UIControlEventTouchUpInside];
    
    self.backgroundColor = [UIColor colorWithRed:236/255.0 green:236/255.0 blue:241/255.0 alpha:1.0];
    self.inputTextView = [[UITextView alloc] initWithFrame:CGRectMake(GAP,8,self.bounds.size.width - EMOJIBUTTON_WIDTH*2 - SENDBUTTON_WIDTH - GAP*2-20,
                                                                    CONTAINVIEW_HEIGHT-15)];
    self.inputTextView.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.inputTextView.textContainerInset = UIEdgeInsetsMake(5, 12, 0, 10);
    //self.inputField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 0)];
    //self.inputField.leftView.userInteractionEnabled = NO;
    //self.inputField.leftViewMode = UITextFieldViewModeAlways;
    self.inputTextView.backgroundColor = [UIColor whiteColor];
    self.inputTextView.font = [UIFont systemFontOfSize:17];
    self.inputTextView.placeholder = [ChatWidget LocalizedString:@"ChatPlaceholderText"];
    self.inputTextView.layer.cornerRadius = 12;
    self.inputTextView.returnKeyType = UIReturnKeySend;
    self.inputTextView.delegate = self;
    self.inputTextView.adjustsFontForContentSizeCategory = NO;
    self.inputTextView.inputAssistantItem.leadingBarButtonGroups = [NSArray array];
    self.inputTextView.inputAssistantItem.trailingBarButtonGroups = [NSArray array];
    [self addSubview:self.inputTextView];
    
    self.emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.emojiButton setImage:[UIImage imageNamedFromBundle:@"icon_emoji"]
                      forState:UIControlStateNormal];
    [self.emojiButton setImage:[UIImage imageNamedFromBundle:@"icon_keyboard"]
                      forState:UIControlStateSelected];
    //self.emojiButton.contentMode = UIViewContentModeScaleAspectFit;
    self.emojiButton.frame = CGRectMake(self.bounds.size.width - EMOJIBUTTON_WIDTH*2 - SENDBUTTON_WIDTH - GAP,
                                        9,
                                        22,
                                        22);
    [self addSubview:self.emojiButton];
    [self.emojiButton addTarget:self
                         action:@selector(emojiButtonAction)
               forControlEvents:UIControlEventTouchUpInside];
    
    self.emojiKeyBoardView = [[EmojiKeyboardView alloc] initWithFrame:CGRectMake(0,0,self.bounds.size.width,176)];
    self.emojiKeyBoardView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    self.imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.imageButton setImage:[UIImage imageNamedFromBundle:@"icon_image"]
                      forState:UIControlStateNormal];
    self.imageButton.contentMode = UIViewContentModeScaleAspectFit;
    self.imageButton.frame = CGRectMake(self.bounds.size.width - EMOJIBUTTON_WIDTH - SENDBUTTON_WIDTH - GAP,
                                        9,
                                        22,
                                        22);
    [self addSubview:self.imageButton];
    [self.imageButton addTarget:self
                         action:@selector(imageButtonAction)
               forControlEvents:UIControlEventTouchUpInside];
}

- (void)changeKeyBoardType
{
    if(self.emojiButton.isSelected) {
            self.inputTextView.inputView = self.emojiKeyBoardView;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.inputTextView reloadInputViews];
            });
        }else{
            self.inputTextView.inputView = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.inputTextView reloadInputViews];
            });
        }
}

- (void)exit
{
    self.hidden = YES;
    self.exitInputButton.hidden = YES;
    self.inputTextView.text = @"";
    [self.inputTextView resignFirstResponder];
}

- (void)sendMsg
{
    NSAttributedString*attr = self.inputTextView.attributedText;
    __block NSString* str = @"";
    [attr enumerateAttributesInRange:NSMakeRange(0, attr.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        EmojiTextAttachment* attachment = [attrs objectForKey:NSAttachmentAttributeName];
        if(attachment){
            NSString* fileType = attachment.emojiStr;
            str = [str stringByAppendingString:fileType];
        }else{
            NSAttributedString* tmp = [attr attributedSubstringFromRange:range];
            str = [str stringByAppendingString:tmp.string];
        }
    }];
    if(str.length > 0) {
        [self.delegate msgWillSend:str];
    }
    [self exit];
}

- (void)sendButtonAction
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendMsg) object:nil];
    [self performSelector:@selector(sendMsg) withObject:nil afterDelay:0.1];
}

- (void)imageButtonAction
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(imageButtonDidClick)]) {
        [self.delegate imageButtonDidClick];
    }
    [self exit];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendButtonAction];
    return YES;
    
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"]) {
        [self sendButtonAction];
        return NO;
    }
    return YES;
}
#pragma mark - CustomKeyBoardDelegate
- (void)emojiItemDidClicked:(NSString *)item{
    NSRange selectedRange = [self selectedRange:self.inputTextView];
    NSMutableAttributedString* attrString = [self.inputTextView.attributedText mutableCopy];
    EmojiTextAttachment* attachMent = [[EmojiTextAttachment alloc] init];
    NSString* imageFileName = [[EMEmojiHelper sharedHelper].emojiFilesDic objectForKey:item];
    if(imageFileName.length == 0) return;
    attachMent.emojiStr = item;
    attachMent.bounds = CGRectMake(0, -2, 17, 17);
    attachMent.image = [UIImage imageNamedFromBundle:imageFileName];
    NSAttributedString *imageStr = [NSAttributedString attributedStringWithAttachment:attachMent];
    [attrString appendAttributedString:imageStr];
    self.inputTextView.attributedText = attrString;
    //self.inputTextView.font = [UIFont systemFontOfSize:17];
 }

 - (void)emojiDidDelete
 {
     if ([self.inputTextView.attributedText length] > 0) {
         NSRange selectedRange = [self selectedRange:self.inputTextView];
         NSMutableAttributedString* attrString = [self.inputTextView.attributedText mutableCopy];
         if(selectedRange.length > 0)
         {
             [attrString deleteCharactersInRange:selectedRange];
         }else{
             if(selectedRange.location > 0)
                 [attrString deleteCharactersInRange:NSMakeRange(selectedRange.location-1, 1)];
         }

         self.inputTextView.attributedText = attrString;
     }
 }

 - (NSRange)selectedRange:(UITextField*)textField
 {
     UITextRange* range = [textField selectedTextRange];
     UITextPosition* beginning = textField.beginningOfDocument;
     UITextPosition* selectionStart = range.start;
     UITextPosition* selectionEnd = range.end;
     const NSInteger location = [textField offsetFromPosition:beginning toPosition:selectionStart];
     const NSInteger length = [textField offsetFromPosition:selectionStart toPosition:selectionEnd];

     return NSMakeRange(location, length);
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
            self.frame = CGRectMake(lastframe.origin.x, lastframe.origin.y - (rect.origin.y - keyboardFrame.origin.y) - CONTAINVIEW_HEIGHT, lastframe.size.width, CONTAINVIEW_HEIGHT);
            
        }
        
    }];
}


#pragma mark --键盘收回
- (void)keyboardDidHide:(NSNotification *)notification{
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:duration animations:^{
        if(duration>0.000001)
        {
            self.hidden = YES;
            self.exitInputButton.hidden = YES;
        }
        [self.delegate keyBoardDidHide:self.inputTextView.text];
    }];
}

- (void)emojiButtonAction
{
    [self.inputTextView becomeFirstResponder];
    [self.emojiButton setSelected:!self.emojiButton.isSelected];
    [self changeKeyBoardType];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
