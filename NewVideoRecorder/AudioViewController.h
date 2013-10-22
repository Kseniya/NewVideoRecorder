//
//  AudioViewController.h
//  NewVideoRecorder
//
//  Created by Kseniya Kalyuk Zito on 10/21/13.
//  Copyright (c) 2013 KZito. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AudioViewController : UIViewController <MPMediaPickerControllerDelegate>

@property(nonatomic, strong) AVAsset *videoAsset;
@property(nonatomic, strong) AVAsset *audioAsset;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

- (IBAction)loadVideo:(id)sender;
- (IBAction)loadAudio:(id)sender;
- (IBAction)merge:(id)sender;
- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller usingDelegate:(id)delegate;
- (void)exportDidFinish:(AVAssetExportSession*)session;

@end

