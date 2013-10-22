//
//  KZCameraView.h
//  VideoRecorder
//
//  Created by Kseniya Kalyuk Zito on 10/21/13.
//  Copyright (c) 2013 Kseniya Kalyuk Zito. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer;

@interface KZCameraView : UIView <UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
}

@property (nonatomic,retain) CaptureManager *captureManager;
@property (nonatomic,retain) IBOutlet UIView *videoPreviewView;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) IBOutlet UILabel *focusModeLabel;
//Progress
@property (nonatomic,retain) IBOutlet UIView *progressView;
@property (nonatomic,retain) IBOutlet UIProgressView *progressBar;
@property (nonatomic,retain) IBOutlet UILabel *progressLabel;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView *activityView;

@property (nonatomic,retain) IBOutlet UIProgressView *durationProgressBar;
@property (nonatomic,assign) float duration;
@property (nonatomic,retain) NSTimer *durationTimer;

#pragma mark Toolbar Actions
- (IBAction)holdScreen:(UILongPressGestureRecognizer*)sender;
- (IBAction)saveVideo:(id)sender;
@end
