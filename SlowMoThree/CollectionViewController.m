//
//  CollectionViewController.m
//  SlowMoThree
//
//  Created by Aditya Narayan on 10/9/15.
//  Copyright © 2015 MR. All rights reserved.
//

#import "CollectionViewController.h"



@interface CollectionViewController () <UINavigationControllerDelegate>

@end

@implementation CollectionViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    items = [[NSMutableArray alloc]initWithContentsOfURL:[NSURL URLWithString:documentDirectory]];
    NSError *error;
    self.docCount = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:documentDirectory error:&error];
    self.colView.delegate=self;
    self.colView.dataSource=self;
    [self.colView setBackgroundColor:[UIColor blackColor]];
    self.collectionTools.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:1.0 alpha:0.2];
}
-(void)viewWillAppear:(BOOL)animated{
}
-(void)viewDidAppear:(BOOL)animated{
}
-(void)viewWillDisappear:(BOOL)animated{
}
-(void)viewDidDisappear:(BOOL)animated{
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.docCount count];
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
    [cell prepareForReuse];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *finalPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, [self.docCount objectAtIndex:indexPath.row]];
    UIImage *img = [self getThumbNail:finalPath];
    UIImageView *imageView = [[UIImageView alloc]init];
    [imageView setFrame:cell.bounds];
    [imageView setImage:img];
    UIImageView *overLay = [[UIImageView alloc]init];
    [overLay setFrame:cell.bounds];
    if (self.checker == 1) {
        self.overlayImage = [UIImage imageNamed:@"deleteOverlay.png"];
        self.vidDelete.imageView.image= [UIImage imageNamed:@"Slice 1.png"];
    }
    else{
        self.overlayImage = [UIImage imageNamed:@"playSymbol.png"];
        self.vidDelete.imageView.image = [UIImage imageNamed:@"deleteButton.png"];
    }
    [overLay setImage:self.overlayImage];
    [imageView addSubview:overLay];
    [cell addSubview: imageView];
    return cell;
}
-(UIImage *)getThumbNail:(NSString*)stringPath{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:stringPath];
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = CMTimeMake(1, 1);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbNail = [[UIImage alloc]init];
    thumbNail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return thumbNail;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    self.pathToPlay = [NSString stringWithFormat:@"%@/%@", documentsDirectory, [self.docCount objectAtIndex:indexPath.row]];
    if (self.checker == 1) {
        //delete
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:self.pathToPlay error:&error];
        self.docCount = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:documentsDirectory error:&error];
         [self.colView reloadData];
    }
    else{
    [[NSUserDefaults standardUserDefaults]setObject:self.pathToPlay forKey:@"pathToPlay"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSegueWithIdentifier:@"toVideoPlayer" sender:self];
    }
}
//UXStuff
-(IBAction)viewPhotos:(id)sender{
}
-(IBAction)deletePhotos:(id)sender{
    if (self.checker == nil) {
    self.checker = 1;//remember to set this back to NIL once you have finished deleting.
    [self.colView reloadData];
    }
    else{
        self.checker = nil;
        [self.colView reloadData];
    }
}
@end
