//
//  Player.m
//  SlowMoThree
//
//  Created by Aditya Narayan on 10/8/15.
//  Copyright © 2015 MR. All rights reserved.
//

#import "Player.h"

@implementation Player

-(AVPlayer *)player{
    return self.playerLayer.player;
}

-(void)setPlayer:(AVPlayer *)player{
    self.playerLayer.player = player;
}
+(Class)layerClass{
    return [AVPlayerLayer class];
}
-(AVPlayerLayer *)playerLayer{
    return (AVPlayerLayer *)self.layer;
}
@end
