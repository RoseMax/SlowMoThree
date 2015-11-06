//
//  PlayerViewController.m
//  SlowMoThree
//
//  Created by Aditya Narayan on 10/8/15.
//  Copyright © 2015 MR. All rights reserved.
//

#import "PlayerViewController.h"
#import "CollectionViewController.h"

@interface PlayerViewController ()
@end
@implementation PlayerViewController
static int playerViewControllerKVOContext = 0;
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
     self.playTools.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:1.0 alpha:0.2];
//    self.rateView.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:1.01 alpha:.2];
    [self.rateSlide setThumbImage:[UIImage imageNamed:@"playSlide2.png"] forState:UIControlStateNormal];
    [self.timeSlider setThumbImage:[UIImage imageNamed:@"sliderThumb.png"] forState:UIControlStateNormal];
//    CGAffineTransform trans = CGAffineTransformMakeRotation(-M_PI_2);
//    self.rateSlide.transform = trans;
    self.rateSlide.minimumValue = 0;
    self.rateSlide.maximumValue = 1;
    NSString *moviePath = [[NSUserDefaults standardUserDefaults]stringForKey:@"pathToPlay"];
    //    NSURL *movieURL = [[NSBundle mainBundle]URLForResource:moviePath withExtension:nil];
    //    NSURL *movieURL = [NSURL URLWithString:moviePath];
    NSURL *movieURL = [NSURL fileURLWithPath:moviePath];
    self.asset = [AVURLAsset assetWithURL:movieURL];
    self.playerItem= [[AVPlayerItem alloc]initWithAsset:self.asset];
    [self addObserver:self forKeyPath:@"asset" options:NSKeyValueObservingOptionNew context:&playerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionInitial context:&playerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionInitial context:&playerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:&playerViewControllerKVOContext];
    self.playerView.playerLayer.player = self.player;
    //self.playerView = self.player;
    PlayerViewController __weak *weakSelf = self;
    _timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        weakSelf.timeSlider.value = CMTimeGetSeconds(time);
    }];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (_timeObserverToken){
        [self.player removeTimeObserver:_timeObserverToken];
        _timeObserverToken = nil;
    }
    [self.player pause];
    [self removeObserver:self forKeyPath:@"asset" context:&playerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.duration" context:&playerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.rate" context:&playerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:&playerViewControllerKVOContext];
}
+(NSArray *)assetKeysRequiredToPlay{
    return @[@"playable", @"hasProtectedContent"];
}
-(AVPlayer *)player{
    if (!_player) {
        _player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    }
    return _player;
}
-(CMTime)currentTime {
    return self.player.currentTime;
}
-(void)setCurrentTime:(CMTime)newCurrentTime{
    [self.player seekToTime:newCurrentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
-(CMTime)duration{
     return self.player.currentItem ? self.player.currentItem.duration : kCMTimeZero;
}
-(float)rate{
    return self.player.rate;
}
-(void)setRate:(float)newRate{
    self.player.rate = newRate;
}
-(AVPlayerLayer *)playerLayer{
    return self.playerView.playerLayer;
}
-(AVPlayerItem*)playerItem{
    return _playerItem;
}
-(void)setPlayerItem:(AVPlayerItem *)newPlayerItem{
    if (_playerItem != newPlayerItem) {
        _playerItem = newPlayerItem;
        [self.player replaceCurrentItemWithPlayerItem:_playerItem];
    }
}
-(void)asynchronouslyLoadURLAsset:(AVURLAsset*)newAsset{
  [newAsset loadValuesAsynchronouslyForKeys:PlayerViewController.assetKeysRequiredToPlay completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (newAsset != self.asset) {
                return;
            }
            for (NSString *key in self.class.assetKeysRequiredToPlay) {
                NSError *error = nil;
                if ([newAsset statusOfValueForKey:key error:&error]==AVKeyValueStatusFailed) {
                    NSString *message = @"can't use this AVAsset because one of it's keys failed to load";
                     [self handleErrorWithMessage:message error:error];
                    return;
                }
            }
            if (!newAsset.playable || newAsset.hasProtectedContent) {
                  NSString *message =  @"Can't use this AVAsset because it isn't playable or has protected content";
                [self handleErrorWithMessage:message error:nil];
                return;
            }
            self.playerItem = [AVPlayerItem playerItemWithAsset:newAsset];
        });
    }];
}
//Action
-(IBAction)playPauseButtonWasPressed:(UIButton *)sender{
    if (self.player.rate != 1.0){
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)){
            self.currentTime = kCMTimeZero;
        }
        [self.player play];
    }
    else{
        [self.player pause];
    }
}
-(IBAction)playStart{
    if (self.player.rate != 1.0){
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)){
            self.currentTime = kCMTimeZero;
        }
        [self.player play];
    }
    else{
        [self.player pause];
    }
}
-(IBAction)playStop:(id)sender{
    [self.player pause];
}

-(IBAction)timeSliderDidChange:(UISlider *)sender{
    self.currentTime = CMTimeMakeWithSeconds(sender.value, 10000);
}
-(IBAction)changePlayback:(id)sender{
    CGFloat rateVal = self.rateSlide.value;
    [self setRate:rateVal];
}
//End Action
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if (context != &playerViewControllerKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if ([keyPath isEqualToString:@"asset"]) {
        if (self.asset) {
            [self asynchronouslyLoadURLAsset:self.asset];
        }
    }
    else if ([keyPath isEqualToString:@"player.currentItem.duration"]){
        CMTime newDuration = self.playerItem.duration;
        BOOL hasValidDuration = CMTIME_IS_NUMERIC(newDuration) && newDuration.value != 0;
        double newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0;
        self.timeSlider.maximumValue = newDurationSeconds;
        self.timeSlider.value = hasValidDuration ? CMTimeGetSeconds(self.currentTime) : 0.0;
        self.timeSlider.enabled = hasValidDuration;
        self.startTimeLabel.enabled = hasValidDuration;
        self.durationLabel.enabled = hasValidDuration;
        int wholeMinutes = (int)trunc(newDurationSeconds / 60);
        self.durationLabel.text = [NSString stringWithFormat:@"%d:%02d", wholeMinutes, (int)trunc(newDurationSeconds) - wholeMinutes * 60];
    }
    else if ([keyPath isEqualToString:@"player.rate"]){
        double newRate = [change[NSKeyValueChangeNewKey] doubleValue];
    }
    else if ([keyPath isEqualToString:@"player.currentItem.status"]){
        NSNumber *newStatusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus newStatus = [newStatusAsNumber isKindOfClass:[NSNumber class]] ? newStatusAsNumber.integerValue : AVPlayerItemStatusUnknown;
        if (newStatus == AVPlayerStatusFailed) {
            [self handleErrorWithMessage:self.player.currentItem.error.localizedDescription error: self.player.currentItem.error];
        }
    }
    else{
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
+(NSSet *)keypathsForValuesAffectingValueForKey:(NSString *)key{
    if ([key isEqualToString:@"duration"]) {
        return [NSSet setWithArray:@[@"player.currentItem.duration"]];
    }
    else if ([key isEqualToString:@"currentTime"]){
        return [NSSet setWithArray:@[@"player,currentItem.currentTime"]];
    }
    else if ([key isEqualToString:@"rate"]){
        return [NSSet setWithArray:@[@"player.rate"]];
    }
    else {
        return [super keyPathsForValuesAffectingValueForKey:key];
    }
}
-(void)handleErrorWithMessage:(NSString *)message error:(NSError *)error{
    NSLog(@"Error occured with message: %@, error: %@.", message, error);
    NSString *alertTitle = @"Alert title for errors";
    NSString *defaultAlertMessage = @"Default error message when no NSError provided";
   UIAlertController *controller = [UIAlertController alertControllerWithTitle:alertTitle message:message ?: defaultAlertMessage preferredStyle:UIAlertControllerStyleAlert];
    NSString *alertActionTitle = @"OK";
      UIAlertAction *action = [UIAlertAction actionWithTitle:alertActionTitle style:UIAlertActionStyleDefault handler:nil];
    [controller addAction:action];
    [self presentViewController:controller animated:YES completion:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
-(IBAction)toColView:(id)sender{
}
-(IBAction)toRecord:(id)sender{
}
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if(size.width>size.height){
            
        }
        else{

        }
    
        
    }];
}
@end
