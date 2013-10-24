//
//  RecorderViewController.m
//  NewVideoRecorder
//
//  Created by Kseniya Kalyuk Zito on 10/23/13.
//  Copyright (c) 2013 KZito. All rights reserved.
//

#import "RecorderViewController.h"
#import "KZCameraView.h"

@interface RecorderViewController ()

@end

@implementation RecorderViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (IOS7)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    //Create CameraView
	KZCameraView *cam = [[KZCameraView alloc]initWithFrame:self.view.frame withVideoPreviewFrame:CGRectMake(0.0, 0.0, 320.0, 320.0)];
    //Create "save" button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:cam action:@selector(saveVideo:)];
    
    [self.view addSubview:cam];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
