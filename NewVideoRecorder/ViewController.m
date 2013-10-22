//
//  ViewController.m
//  NewVideoRecorder
//
//  Created by Kseniya Kalyuk Zito on 10/21/13.
//  Copyright (c) 2013 KZito. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if (IOS7)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
