VideoRecorder
================

Vine like video recorder. Hold you finger - record, let it go - stop recording.
Also ability to add audio track from itunes library to any video from camera roll.

Still needs some work.

Can be easily used in other project just copy VideoRecorder folder to your project. 

Add Camera View into you view controller 


       KZCameraView *cam = [[KZCameraView alloc]initWithFrame:self.view.frame withVideoPreviewFrame:CGRectMake(0.0, 0.0, 320.0, 320.0)];
       [self.view addSubview:cam];

Create a button (in example project bar button) to save recorded video.

       self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:cam action:@selector(saveVideo:)];

