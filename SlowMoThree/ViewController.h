#import <UIKit/UIKit.h>
#import "CollectionViewController.h"
@import AVFoundation;
@import Photos;
#import "Preview.h"


static void * CaptureStillImageContext = &CaptureStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;

typedef NS_ENUM(NSInteger, AVCamSetupResult){
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};
@interface ViewController : UIViewController <AVCaptureFileOutputRecordingDelegate>
//UX
@property (nonatomic, weak) IBOutlet Preview *preview;
@property (nonatomic, weak) IBOutlet UILabel *cameraUnavailableLabel;
@property (nonatomic, weak) IBOutlet UIButton *resumeButton;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet UIButton *getPhotos;
@property (nonatomic, weak) IBOutlet UISegmentedControl *fpsControl;
@property (weak, nonatomic) IBOutlet UIView *toolView;
@property (weak, nonatomic) IBOutlet UIButton *recLabel;
@property (weak, nonatomic) IBOutlet UIImageView *crossHairs;
@property (weak, nonatomic) IBOutlet UILabel *hold;
@property (weak, nonatomic) IBOutlet UIImageView *rec;
@property (weak, nonatomic) IBOutlet UILabel *toRecord;

@property (weak, nonatomic) IBOutlet UILabel *segLabel;


//Session
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

//Other
@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

-(void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS;


@end

