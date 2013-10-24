//
//  KZCameraView.h
//  VideoRecorder
//
//  Created by Kseniya Kalyuk Zito on 10/21/13.
//  Copyright (c) 2013 Kseniya Kalyuk Zito. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer;

@interface KZCameraView : UIView <UIImagePickerControllerDelegate,UINavigationControllerDelegate>

- (id)initWithFrame:(CGRect)frame withVideoPreviewFrame:(CGRect)videoFrame;

#pragma mark Toolbar Actions
- (IBAction)holdScreen:(UILongPressGestureRecognizer*)sender;
- (IBAction)saveVideo:(id)sender;
@end
