//
//  ViewController.m
//  SlowMoThree
//
//  Created by Aditya Narayan on 10/7/15.
//  Copyright © 2015 MR. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <AVCaptureFileOutputRecordingDelegate, UINavigationControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    self.recLabel.hidden = YES;
    self.crossHairs.hidden = YES;
    self.recordButton.enabled = NO;
    self.navigationController.navigationBar.hidden = YES;
    self.toolView.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:1.0 alpha:0.2];
    self.session = [[AVCaptureSession alloc]init];
    self.preview.session = self.session;
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    self.setupResult = AVCamSetupResultSuccess;
    //check permissions
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:{
            break;
        }
        case AVAuthorizationStatusNotDetermined:{
            dispatch_suspend(self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (!granted) {
                    self.setupResult =AVCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume(self.sessionQueue);
            }];
            break;
        }
        default:{
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    
    }
    //capture
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult !=AVCamSetupResultSuccess) {
            return;
        }
        self.backgroundRecordingID = UIBackgroundTaskInvalid;
        NSError *error = nil;
        self.videoDevice = [ViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:&error];
        if (!videoDeviceInput) {
            NSLog(@"Could not create video device input: %@", error);
        }
        [self.session beginConfiguration];
        if ([self.session canAddInput:videoDeviceInput]) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                AVCaptureVideoOrientation initialVideoOrientation =AVCaptureVideoOrientationPortrait;
                if (statusBarOrientation != UIInterfaceOrientationUnknown) {
                    initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                }
                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.preview.layer;
                previewLayer.connection.videoOrientation = initialVideoOrientation;
            });
        }
        else{
            NSLog(@"Could not add video device input to the session");
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        if (! audioDeviceInput) {
            NSLog(@"Could not creat audio device input: %@", error);
        }
        if ([self.session canAddInput:audioDeviceInput]) {
            [self.session addInput:audioDeviceInput];
        }
        else {
            NSLog(@"Could not add audiot device input to the session");
        }
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
        if ([self.session canAddOutput:movieFileOutput]) {
            [self.session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if (connection.isVideoStabilizationSupported) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            self.movieFileOutput = movieFileOutput;
        }
        else{
            NSLog(@"Could not add movie file to the session");
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
        if ([self.session canAddOutput:stillImageOutput]) {
            stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
            [self.session addOutput:stillImageOutput];
            self.stillImageOutput = stillImageOutput;
        }
        else{
            NSLog(@"Could not add still image output to the session");
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        [self.session commitConfiguration];
    });
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    dispatch_async(self.sessionQueue, ^{
        switch (self.setupResult) {
            case AVCamSetupResultSuccess:{
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case AVCamSetupResultCameraNotAuthorized:{
                    dispatch_async( dispatch_get_main_queue(), ^{
                        NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                        [alertController addAction:cancelAction];
                        // Provide quick access to Settings.
                        UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                        }];
                        [alertController addAction:settingsAction];
                        [self presentViewController:alertController animated:YES completion:nil];
                    } );
                    break;
                }
            case AVCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    } );
}
-(void)viewDidDisappear:(BOOL)animated{
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult == AVCamSetupResultSuccess) {
            [self.session stopRunning];
//            [self removeObersvers];
        }
    });
    [super viewDidDisappear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
+(AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    for (AVCaptureDevice *device in devices) {
        if (device.position ==position) {
            captureDevice=device;
            break;
        }
    }
    return captureDevice;
}
-(void)addObservers{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CaptureStillImageContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
   
}
-(void)removeObersvers{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
    [self.stillImageOutput removeObserver:self forKeyPath:@"captureStillImage" context:CaptureStillImageContext];
}
- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

-(void)sessionInterruptionEnded:(NSNotification *)notification{
    NSLog(@"Capture session interruption ended");
    if (!self.resumeButton.hidden) {
        [UIView animateWithDuration:0.25 animations:^{
            self.resumeButton.alpha = 0.0;
        }completion:^(BOOL finished) {
            self.resumeButton.hidden = YES;
        }];
    }
    if (!self.cameraUnavailableLabel.hidden) {
        [UIView animateWithDuration:0.25 animations:^{
            self.cameraUnavailableLabel.alpha = 0.0;
        }completion:^(BOOL finished) {
            self.cameraUnavailableLabel.hidden = YES;
        }];
    }
}
-(void)sessionRuntimeError:(NSNotification*)notification{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog(@"Capture session runtime error: %@", error);
    if (error.code == AVErrorMediaServicesWereReset) {
        dispatch_async(self.sessionQueue, ^{
            if (self.isSessionRunning) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            }
            else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.resumeButton.hidden = NO;
                });
            }
        });
    }
    else{
        self.resumeButton.hidden = NO;
    }
}
- (void)sessionWasInterrupted:(NSNotification *)notification{
    BOOL showResumeButton = NO;
    if ( &AVCaptureSessionInterruptionReasonKey ) {
        AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
        NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
        
        if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
            reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
            showResumeButton = YES;
        }
        else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps ) {            self.cameraUnavailableLabel.hidden = NO;
            self.cameraUnavailableLabel.alpha = 0.0;
            [UIView animateWithDuration:0.25 animations:^{
                self.cameraUnavailableLabel.alpha = 1.0;
            }];
        }
    }
    else {
        NSLog( @"Capture session was interrupted" );
        showResumeButton = ( [UIApplication sharedApplication].applicationState == UIApplicationStateInactive );
    }
    
    if ( showResumeButton ) {        self.resumeButton.hidden = NO;
        self.resumeButton.alpha = 0.0;
        [UIView animateWithDuration:0.25 animations:^{
            self.resumeButton.alpha = 1.0;
        }];
    }
}
//Orientation Shit
-(BOOL)shouldAutorotate{
    return ! self.movieFileOutput.isRecording;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    self.recordButton.hidden =YES;
    self.fpsControl.hidden = YES;
    self.getPhotos.hidden = YES;
    self.segLabel.hidden = YES;
    self.toolView.hidden = YES;
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation)||UIDeviceOrientationIsLandscape(deviceOrientation)) {
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.preview.layer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.recordButton.hidden =NO;
        self.fpsControl.hidden = NO;
        self.getPhotos.hidden = NO;
        self.segLabel.hidden = NO;
        self.toolView.hidden = NO;
        CGRect recFrame = self.recordButton.frame;
        CGRect segFrame = self.fpsControl.frame;
        CGRect photoFrame = self.getPhotos.frame;
        CGRect segLabelFrame = self.segLabel.frame;
        CGRect toolFrame = self.toolView.frame;
        CGRect crossFrame = self.crossHairs.frame;
        if(size.width>size.height){
            
            toolFrame = CGRectMake(512, 0, 56, 320);
            recFrame = CGRectMake(5, 25, 45, 45);
            self.fpsControl.hidden = YES;
            self.segLabel.hidden = YES;
            photoFrame = CGRectMake(5, 250, 45, 45);
            crossFrame = CGRectMake(40, 40, 420, 240);
            self.crossHairs.image = [UIImage imageNamed:@"Blank.png"];
        }
        else{
            toolFrame = CGRectMake(0, 512, 320, 56);
            recFrame = CGRectMake(25, 5, 45, 45);
            segFrame = CGRectMake(100, 20, 121, 28);
            photoFrame = CGRectMake(250, 5, 45, 45);
            segLabelFrame =CGRectMake(100, 0, 121, 21);
            crossFrame = CGRectMake(40, 40, 240, 420);
            self.fpsControl.hidden = NO;
            self.segLabel.hidden = NO;
            self.crossHairs.image = [UIImage imageNamed:@"CrossHairs.png"];
        }
        self.toolView.frame = toolFrame;
        self.recordButton.frame = recFrame;
        self.fpsControl.frame = segFrame;
        self.getPhotos.frame = photoFrame;
        self.segLabel.frame = segLabelFrame;

        
    }];
}
//end Orientation
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if (context == CaptureStillImageContext) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        if (isCapturingStillImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.preview.layer.opacity =0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.preview.layer.opacity = 1.0;
                }];
            });
        }
    }
    else if (context == SessionRunningContext){
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.recordButton.enabled = isSessionRunning;
        });
    }
    else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
//Action
-(IBAction)resumeInterruptedSession:(id)sender{
    dispatch_async(self.sessionQueue, ^{
        [self.session startRunning];
        self.sessionRunning = self.session.isRunning;
        if (! self.session.isRunning) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = NSLocalizedString( @"Unable to resume", @"Alert message when unable to resume the session running" );
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
            } );
        }
        else {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.resumeButton.hidden = YES;
            } );
        }
    } );
}
-(IBAction)pressDown{
    dispatch_async(self.sessionQueue, ^{
        if (! self.movieFileOutput.isRecording) {
            if ([UIDevice currentDevice].isMultitaskingSupported) {
                self.backgroundRecordingID = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:nil];
            }
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.preview.layer;
            connection.videoOrientation = previewLayer.connection.videoOrientation;
            [ViewController setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDeviceInput.device];
            
            NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
            NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject];
            //            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:
            //                                        [outputFileName stringByAppendingPathExtension:@"mov"]];
            NSString *outputFilePath = [documentsPath stringByAppendingPathComponent:outputFileName];
            NSString *outputFilePathFinal = [outputFilePath stringByAppendingPathExtension:@"mov"];
            
            [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePathFinal] recordingDelegate:self];
        }
        else{
            [self.movieFileOutput stopRecording];
        }
    });
}

-(IBAction)liftUp{
    dispatch_async(self.sessionQueue, ^{
     [self.movieFileOutput stopRecording];
            });
}

-(IBAction)toggleMovieRecording:(id)sender{
    self.recordButton.enabled = NO;
    
    dispatch_async(self.sessionQueue, ^{
        if (! self.movieFileOutput.isRecording) {
            if ([UIDevice currentDevice].isMultitaskingSupported) {
                self.backgroundRecordingID = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:nil];
            }
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.preview.layer;
            connection.videoOrientation = previewLayer.connection.videoOrientation;
            [ViewController setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDeviceInput.device];
            
            NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
             NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject];
//            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:
//                                        [outputFileName stringByAppendingPathExtension:@"mov"]];
             NSString *outputFilePath = [documentsPath stringByAppendingPathComponent:outputFileName];
            NSString *outputFilePathFinal = [outputFilePath stringByAppendingPathExtension:@"mov"];
    
            [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePathFinal] recordingDelegate:self];
        }
        else{
            [self.movieFileOutput stopRecording];
        }
    });
}
-(IBAction)changeCamera:(id)sender{
    self.recordButton.enabled = NO;
     dispatch_async(self.sessionQueue, ^{
         AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
         AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
         AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
         switch (currentPosition) {
             case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                 preferredPosition = AVCaptureDevicePositionBack;
                 break;
            case AVCaptureDevicePositionBack:
                 preferredPosition = AVCaptureDevicePositionFront;
                 break;
         }
         self.videoDevice = [ViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
         AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:nil];
         [self.session beginConfiguration];
         [self.session removeInput:self.videoDeviceInput];
         if ([self.session canAddInput:videoDeviceInput]) {
             [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDevice];
             [self.session addInput:videoDeviceInput];
             self.videoDeviceInput = videoDeviceInput;
         }
         else{
             [self.session commitConfiguration];
         }
         
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.recordButton.enabled = YES;
             });
     });
}
-(IBAction)viewPhotos:(id)sender{
//    [self performSegueWithIdentifier:@"collectionViewSeg" sender:self];
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device{
    if (device.hasFlash && [device isFlashModeSupported:flashMode]) {
        NSError *error =nil;
        if ([device lockForConfiguration:&error]) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        }
        else{
            NSLog(@"Could not lock device for configuration %@", error);
        }
    }
}
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recordButton.enabled = YES;
        //[self.recordButton setTitle:NSLocalizedString(@"Stop", @"Recording button stop title") forState:UIControlStateNormal];
        [self.recordButton setImage:[UIImage imageNamed:@"Stop.png"] forState:UIControlStateNormal];
        self.hold.hidden = YES;
        self.rec.hidden = YES;
        self.toRecord.hidden = YES;
        self.recLabel.hidden = NO;
        self.crossHairs.hidden =NO;
    });
}
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    dispatch_async( dispatch_get_main_queue(), ^{
        self.recordButton.enabled = YES;
       // [self.recordButton setTitle:NSLocalizedString( @"Record", @"Recording button record title" ) forState:UIControlStateNormal];
        [self.recordButton setImage:[UIImage imageNamed:@"rec.png"] forState:UIControlStateNormal];
        self.hold.hidden = NO;
        self.rec.hidden = NO;
        self.toRecord.hidden = NO;
        self.recLabel.hidden = YES;
        self.crossHairs.hidden = YES;
    });
}
-(void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS{
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    for (AVCaptureDeviceFormat *format in [self.videoDevice formats]){
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges){
            CMFormatDescriptionRef description = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(description);
            int32_t width = dimensions.width;
            if (range.maxFrameRate == desiredFPS && width <= 1920) {
            selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    if (selectedFormat) {
        if ([self.videoDevice lockForConfiguration:nil]) {
            self.videoDevice.activeFormat = selectedFormat;
            self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [self.videoDevice unlockForConfiguration];
        }
    }
}
-(IBAction)fpsChanged:(UISegmentedControl *)sender{
        CGFloat desiredFPS = 0.0;
        switch (self.fpsControl.selectedSegmentIndex) {
            case 0:
            {
                desiredFPS = 30.0;
                break;
            }
            case 1:{
                desiredFPS = 120.0;
                break;
            }
            default:
                break;
        }
    dispatch_queue_t queue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        if (desiredFPS > 0.0) {
            [self switchFormatWithDesiredFPS:desiredFPS];
        }
        else{
            NSLog(@"Switch Didn't fire");
        }
    });
}

@end

