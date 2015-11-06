//
//  PlayerViewController.h
//  SlowMoThree
//
//  Created by Aditya Narayan on 10/8/15.
//  Copyright © 2015 MR. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Foundation;
@import AVFoundation;
@import CoreMedia.CMTime;
#import "Player.h"

//@class Player;

@interface PlayerViewController : UIViewController
{
    AVPlayer *_player;
    AVURLAsset *_asset;
    id<NSObject> _timeObserverToken;
    AVPlayerItem *_playerItem;
}
@property AVPlayerItem *playerItem;
@property (readonly) AVPlayerLayer *playerLayer;
@property (readonly) AVPlayer *player;
@property AVURLAsset *asset;
@property CMTime currentTime;
@property (readonly) CMTime duration;
@property float rate;

//UIStuff
@property (weak, nonatomic) IBOutlet UIView *rateView;

@property (weak) IBOutlet UISlider *timeSlider;
@property (weak) IBOutlet UILabel *startTimeLabel;
@property (weak) IBOutlet UILabel *durationLabel;
@property (weak) IBOutlet Player *playerView;
@property (weak, nonatomic) IBOutlet UISlider *rateSlide;
@property (weak, nonatomic) IBOutlet UIView *playTools;
@end
