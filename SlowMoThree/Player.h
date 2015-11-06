//
//  Player.h
//  SlowMoThree
//
//  Created by Aditya Narayan on 10/8/15.
//  Copyright © 2015 MR. All rights reserved.
//

@import  UIKit;
@import Foundation;
@import AVFoundation;

@class AVPlayer;

@interface Player : UIView
@property AVPlayer *player;
@property (nonatomic, retain) AVPlayerLayer *playerLayer;
@end
