//
//  KZCameraView.m
//  VideoRecorder
//
//  Created by Kseniya Kalyuk Zito on 10/21/13.
//  Copyright (c) 2013 Kseniya Kalyuk Zito. All rights reserved.
//

#import "KZCameraView.h"
#import "CaptureManager.h"
#import "AVCamRecorder.h"
#import <AVFoundation/AVFoundation.h>

#define MAX_DURATION 10

static void *AVCamFocusModeObserverContext = &AVCamFocusModeObserverContext;

@interface KZCameraView () <UIGestureRecognizerDelegate>

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

@end

@interface KZCameraView (InternalMethods) <UIGestureRecognizerDelegate>

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer;

@end

@interface KZCameraView (CaptureManagerDelegate) <CaptureManagerDelegate>
@end

@implementation KZCameraView

- (id)initWithFrame:(CGRect)frame withVideoPreviewFrame:(CGRect)videoFrame
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([self captureManager] == nil) {
            CaptureManager *manager = [[CaptureManager alloc] init];
            [self setCaptureManager:manager];
            
            [[self captureManager] setDelegate:self];
            
            if ([[self captureManager] setupSession]) {
                // Create video preview layer and add it to the UI
                AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[[self captureManager] session]];
                
                self.videoPreviewView = [[UIView alloc]init];
                self.videoPreviewView.frame =  CGRectMake(0.0, 0.0, videoFrame.size.width, videoFrame.size.width);
                CALayer *viewLayer = self.videoPreviewView.layer;
                [viewLayer setMasksToBounds:YES];
                [self addSubview:self.videoPreviewView];
                
                CGRect bounds = self.videoPreviewView.bounds;
                [newCaptureVideoPreviewLayer setFrame:bounds];
                NSLog(@"%f, %f, %f, %f", newCaptureVideoPreviewLayer.frame.origin.x, newCaptureVideoPreviewLayer.frame.origin.y, newCaptureVideoPreviewLayer.frame.size.width, newCaptureVideoPreviewLayer.frame.size.height);
                
                if ([newCaptureVideoPreviewLayer.connection isVideoOrientationSupported]) {
                    [newCaptureVideoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                }
                
                [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                
                [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
                
                [self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
                
                // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[[self captureManager] session] startRunning];
                });
                
                //Record Long Press Gesture
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(holdScreen:)];
                [longPress setDelegate:self];
                [self addGestureRecognizer:longPress];
                
                self.durationProgressBar = [[UIProgressView alloc]initWithFrame:CGRectMake(0.0, videoFrame.origin.y + videoFrame.size.height, videoFrame.size.width, 2.0)];
                [self addSubview:self.durationProgressBar];
                
                // Create the focus mode UI overlay
                UILabel *newFocusModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, viewLayer.bounds.size.width - 20, 20)];
                [newFocusModeLabel setBackgroundColor:[UIColor clearColor]];
                [newFocusModeLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.50]];
                AVCaptureFocusMode initialFocusMode = [[[self.captureManager videoInput] device] focusMode];
                [newFocusModeLabel setText:[NSString stringWithFormat:@"focus: %@", [self stringForFocusMode:initialFocusMode]]];
                [self.videoPreviewView addSubview:newFocusModeLabel];
                [self addObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:AVCamFocusModeObserverContext];
                [self setFocusModeLabel:newFocusModeLabel];
                
                // Add a single tap gesture to focus on the point tapped, then lock focus
                UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
                [singleTap setDelegate:self];
                [singleTap setNumberOfTapsRequired:1];
                [self.videoPreviewView addGestureRecognizer:singleTap];
                
                // Add a double tap gesture to reset the focus mode to continuous auto focus
                UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
                [doubleTap setDelegate:self];
                [doubleTap setNumberOfTapsRequired:2];
                [singleTap requireGestureRecognizerToFail:doubleTap];
                [self.videoPreviewView addGestureRecognizer:doubleTap];
                
                //Create progress view for saving the video
                self.progressView = [[UIView alloc]initWithFrame:videoFrame];
                self.progressView.backgroundColor = [UIColor clearColor];
                self.progressView.hidden = YES;
                
                self.progressBar = [[UIProgressView alloc]initWithFrame:CGRectMake(0.0, 0.0, videoFrame.size.width - 60.0, 2.0)];
                
                self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, videoFrame.size.width - 60.0, 20.0)];
                self.progressLabel.backgroundColor = [UIColor clearColor];
                self.progressLabel.textColor = [UIColor whiteColor];
                self.progressLabel.textAlignment = NSTextAlignmentCenter;
                
                self.activityView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)];
                self.activityView.hidesWhenStopped = YES;
                
                self.progressBar.center = self.progressView.center;
                self.activityView.center = self.progressView.center;
                self.progressLabel.center = CGPointMake(self.progressView.center.x, self.progressView.center.y + 20.0);
                
                [self addSubview:self.progressView];
                [self.progressView addSubview:self.progressBar];
                [self.progressView addSubview:self.progressLabel];
                [self.progressView addSubview:self.activityView];
            }
        }
    }
    return self;
}


- (NSString *)stringForFocusMode:(AVCaptureFocusMode)focusMode
{
	NSString *focusString = @"";
	
	switch (focusMode) {
		case AVCaptureFocusModeLocked:
			focusString = @"locked";
			break;
		case AVCaptureFocusModeAutoFocus:
			focusString = @"auto";
			break;
		case AVCaptureFocusModeContinuousAutoFocus:
			focusString = @"continuous";
			break;
	}
	
	return focusString;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVCamFocusModeObserverContext) {
        // Update the focus UI overlay string when the focus mode changes
		[self.focusModeLabel setText:[NSString stringWithFormat:@"focus: %@", [self stringForFocusMode:(AVCaptureFocusMode)[[change objectForKey:NSKeyValueChangeNewKey] integerValue]]]];
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark

- (IBAction)holdScreen:(UILongPressGestureRecognizer*)recognizer
{
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            NSLog(@"START");
            if (![[[self captureManager] recorder] isRecording])
            {
                if (self.duration < MAX_DURATION)
                {
                    [[self captureManager] startRecording];
                }
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if ([[[self captureManager] recorder] isRecording])
            {
                [self.durationTimer invalidate];
                [[self captureManager] stopRecording];
                self.videoPreviewView.layer.borderColor = [UIColor clearColor].CGColor;
                NSLog(@"END number of pieces %lu", (unsigned long)[self.captureManager.assetsURLs count]);
            }
            break;
        }
        default:
            break;
    }
}

- (void) updateDuration
{
    if ([[[self captureManager] recorder] isRecording])
    {
        self.duration = self.duration + 0.1;
        self.durationProgressBar.progress = self.duration/MAX_DURATION;
        NSLog(@"self.duration %f, self.progressBar %f", self.duration, self.durationProgressBar.progress);
        if (self.durationProgressBar.progress > .99) {
            [self.durationTimer invalidate];
            self.durationTimer = nil;
            [[self captureManager] stopRecording];
        }
    }
    else
    {
        [self.durationTimer invalidate];
        self.durationTimer = nil;
    }
}

- (IBAction)saveVideo:(id)sender {
    [self.captureManager saveVideo];
}

@end

@implementation KZCameraView (InternalMethods)

// Convert from view coordinates to camera coordinates, where {0,0} represents the top left of the picture area, and {1,1} represents
// the bottom right in landscape mode with the home button on the right.
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = self.videoPreviewView.frame.size;
    
    if ([self.captureVideoPreviewLayer.connection isVideoMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    if ( [[self.captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
		// Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[self captureManager] videoInput] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[self.captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[self.captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[self.captureManager videoInput] device] isFocusPointOfInterestSupported]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:[self videoPreviewView]];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        [self.captureManager autoFocusAtPoint:convertedFocusPoint];
    }
}

// Change to continuous auto focus. The camera will constantly focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[self.captureManager videoInput] device] isFocusPointOfInterestSupported])
        [self.captureManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

@end

@implementation KZCameraView (CaptureManagerDelegate)

- (void) updateProgress
{
    self.progressView.hidden = NO;
    self.progressBar.hidden = NO;
    self.activityView.hidden = YES;
    self.progressLabel.text = @"Creating the video";
    self.progressBar.progress = self.captureManager.exportSession.progress;
    if (self.progressBar.progress > .99) {
        [self.captureManager.exportProgressBarTimer invalidate];
        self.captureManager.exportProgressBarTimer = nil;
    }
}

- (void) removeProgress
{
    self.progressBar.hidden = YES;
    [self.activityView startAnimating];
    self.progressLabel.text = @"Saving to Camera Roll";
}

- (void) doneSavingWithError:(BOOL)error
{
    if (error) {
        self.progressLabel.text = @"Video Saving Failed";
    } else {
        self.progressLabel.text = @"Saved To Photo Album";
        [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
    }
    
    [self.activityView stopAnimating];
}

-(void)refresh
{
    self.progressView.hidden = YES;
    self.duration = 0.0;
    self.durationProgressBar.progress = 0.0;
    [self.durationTimer invalidate];
    self.durationTimer = nil;
}

- (void)captureManager:(CaptureManager *)captureManager didFailWithError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

- (void)captureManagerRecordingBegan:(CaptureManager *)captureManager
{
    self.videoPreviewView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.videoPreviewView.layer.borderWidth = 2.0;
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
}

- (void)captureManagerRecordingFinished:(CaptureManager *)captureManager
{
}

- (void)captureManagerDeviceConfigurationChanged:(CaptureManager *)captureManager
{
    //Do something
}

@end
