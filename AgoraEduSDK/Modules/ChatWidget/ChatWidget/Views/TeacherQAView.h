//
//  TeacherQAView.h
//  ChatWidget
//
//  Created by lixiaoming on 2021/9/15.
//

#import <UIKit/UIKit.h>
#import "QAView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TeacherQAViewDelegate <NSObject>

- (void)teacherQAViewDidClose;

@end

@interface TeacherQAView : UIView
@property (nonatomic,weak) id<TeacherQAViewDelegate> delegate;
@property (nonatomic,strong) QAView* qaView;
- (void)resetMsgs:(NSMutableArray*)msgArray;
- (void)addMsgs:(NSMutableArray*)msgArray;
@end

NS_ASSUME_NONNULL_END
