#import <UIKit/UIKit.h>
@import AVFoundation;

@class AVCaptureSession;
@interface Preview : UIView
@property (nonatomic) AVCaptureSession *session;
@end
