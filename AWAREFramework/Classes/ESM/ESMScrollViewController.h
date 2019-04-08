//
//  ESMScrollViewController.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/29.
//

#import <UIKit/UIKit.h>
#import "BaseESMView.h"

//@protocol ESMScrollViewControllerDelegate <NSObject>
//@required
//@optional
//- (void) didCompleteDataUpload:(bool)status;
//@end

@interface ESMScrollViewController : UIViewController <UIImagePickerControllerDelegate, UIScrollViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UIAlertViewDelegate>

typedef void (^ESMAnswerCompletionHandler)(void);
typedef void (^ESMAnswerUploadStartHandler)(void);
typedef void (^ESMAnswerUploadCompletionHandler)(bool state);
typedef BaseESMView * _Nullable (^OriginalESMViewGenerationHandler)(EntityESM * _Nonnull esm, double bottomESMViewPositionY, UIViewController * _Nonnull viewController);

// @property (nonatomic, weak) id<ESMScrollViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIScrollView * _Nullable mainScrollView;
@property (nonatomic, strong) UITapGestureRecognizer * _Nullable singleTap;
@property (nullable) NSMutableArray * esms;

@property bool isSaveAnswer;

@property (nullable) NSString * submitButtonText;
@property (nullable) NSString * cancelButtonText;

/////// Completion Alert
@property bool sendCompletionAlert;
@property (nullable) NSString * completionAlertMessage;
@property (nullable) NSString * completionAlertCloseButton;

/////// Uploading Progress
// @property bool showUploadingAlert;
// @property NSString * uploadingAlertMessage;

@property ESMAnswerUploadStartHandler      _Nullable uploadStartHandler;
@property ESMAnswerUploadCompletionHandler _Nullable uploadCompletionHandler;
@property ESMAnswerCompletionHandler       _Nullable answerCompletionHandler;
@property OriginalESMViewGenerationHandler _Nullable originalESMViewGenerationHandler;

- (void) setESMAnswerUploadStartHandler:(ESMAnswerUploadStartHandler _Nonnull)handler;
- (void) setESMAnswerUploadCompletionHandler:(ESMAnswerUploadCompletionHandler _Nonnull)handler;
- (void) setESMAnswerCompletionHandler:(ESMAnswerCompletionHandler _Nonnull)handler;
- (void) setOriginalESMViewGenerationHandler:(OriginalESMViewGenerationHandler _Nonnull)handler;

@end
