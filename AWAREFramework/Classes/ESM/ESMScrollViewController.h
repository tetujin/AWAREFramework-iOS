//
//  ESMScrollViewController.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/29.
//

#import <UIKit/UIKit.h>

//@protocol ESMScrollViewControllerDelegate <NSObject>
//@required
//@optional
//- (void) didCompleteDataUpload:(bool)status;
//@end

@interface ESMScrollViewController : UIViewController <UIImagePickerControllerDelegate, UIScrollViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UIAlertViewDelegate>

typedef void (^ESMAnswerCompletionHandler)(void);
typedef void (^ESMAnswerUploadStartHandler)(void);
typedef void (^ESMAnswerUploadCompletionHandler)(bool state);

// @property (nonatomic, weak) id<ESMScrollViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property(nonatomic, strong) UITapGestureRecognizer *singleTap;
@property NSMutableArray * esms;

@property bool isSaveAnswer;

@property NSString * submitButtonText;
@property NSString * cancelButtonText;

/////// Completion Alert
@property bool sendCompletionAlert;
@property NSString * completionAlertMessage;
@property NSString * completionAlertCloseButton;

/////// Uploading Progress
// @property bool showUploadingAlert;
// @property NSString * uploadingAlertMessage;

@property ESMAnswerUploadStartHandler uploadStartHandler;
@property ESMAnswerUploadCompletionHandler uploadCompletionHandler;
@property ESMAnswerCompletionHandler answerCompletionHandler;

@end
