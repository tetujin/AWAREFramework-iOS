//
//  ESMScrollViewController.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/29.
//

#import <UIKit/UIKit.h>
#import "BaseESMView.h"
#import "EntityESMAnswer.h"
#import "AWAREStorage.h"

//@protocol ESMScrollViewControllerDelegate <NSObject>
//@required
//@optional
//- (void) didCompleteDataUpload:(bool)status;
//@end

@interface ESMScrollViewController : UIViewController <UIImagePickerControllerDelegate, UIScrollViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UIAlertViewDelegate>

typedef void (^AllESMCompletionHandler)(void);
typedef void (^ESMAnswerUploadStartHandler)(void);
typedef void (^ESMAnswerUploadCompletionHandler)(bool state);
typedef BaseESMView * _Nullable (^OriginalESMViewGenerationHandler)(EntityESM * _Nonnull esm, double bottomESMViewPositionY, UIViewController * _Nonnull viewController);
typedef void (^ESMCompletionHandler)(EntityESMAnswer * _Nonnull answer);
typedef void (^ESMScrollViewUIComponentReadyHandler)(void);

// @property (nonatomic, weak) id<ESMScrollViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIScrollView * _Nullable mainScrollView;
@property (nonatomic, strong) UITapGestureRecognizer * _Nullable singleTap;
@property (nullable) NSMutableArray * esms;

@property bool isSaveAnswer;

@property (nullable) NSString * submitButtonText;
@property (nullable) NSString * cancelButtonText;

/////// Completion Alert
@property bool sendCompletionAlert;
@property (nullable) NSString * completionAlertTitle;
@property (nullable) NSString * completionAlertMessage;
@property (nullable) NSString * completionAlertErrorTitle;
@property (nullable) NSString * completionAlertErrorMessage;
@property (nullable) NSString * completionAlertCloseButton;

/////// Uploading Progress
// @property bool showUploadingAlert;
// @property NSString * uploadingAlertMessage;

- (void) setESMAnswerUploadStartHandler:(ESMAnswerUploadStartHandler _Nullable)handler;
- (void) setESMAnswerUploadCompletionHandler:(ESMAnswerUploadCompletionHandler _Nullable)handler;

- (void) setESMAnswerCompletionHandler:(AllESMCompletionHandler _Nullable)handler;
- (void) setAllESMCompletionHandler:(AllESMCompletionHandler _Nullable)handler;

- (void) setOriginalESMViewGenerationHandler:(OriginalESMViewGenerationHandler _Nullable)handler;
- (void) setESMCompletionHandler:(ESMCompletionHandler _Nullable)handler;
- (void) setESMScrollViewUIComponentReadyHandler:(ESMScrollViewUIComponentReadyHandler _Nullable)handler;
- (void) setOriginalStorageSyncHandler:(SyncProcessCallback _Nullable)handler;

- (void) insertNextESM:(ESMItem * _Nonnull) esm;


@end
