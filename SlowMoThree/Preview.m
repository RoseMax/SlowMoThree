#import "Preview.h"

@implementation Preview
+(Class)layerClass{
    return [AVCaptureVideoPreviewLayer class];
}
-(AVCaptureSession *)session{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    return previewLayer.session;
}
-(void)setSession:(AVCaptureSession *)session{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    previewLayer.session = session;
}
@end
