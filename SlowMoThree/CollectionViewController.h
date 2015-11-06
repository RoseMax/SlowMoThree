//
//  CollectionViewController.h
//  SlowMoThree
//
//  Created by Aditya Narayan on 10/9/15.
//  Copyright © 2015 MR. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;


@interface CollectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    NSMutableArray *items;
//    IBOutlet UICollectionView *itemsTable;
}
//UXStuff
@property (nonatomic, strong) NSArray *docCount;
@property (weak, nonatomic) IBOutlet UICollectionView *colView;
@property (nonatomic, strong) NSString *pathToPlay;
@property (weak, nonatomic) IBOutlet UIView *collectionTools;
@property (weak, nonatomic) IBOutlet UIButton *goBack;
@property (weak, nonatomic) IBOutlet UIButton *vidDelete;
@property (weak, nonatomic) UIImage *overlayImage;

//Delete Stff
@property (nonatomic) int checker;

//Data





@end
