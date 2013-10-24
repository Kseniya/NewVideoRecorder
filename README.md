VideoRecorder
================

Vine like video recorder. Hold you finger - record, let it go - stop recording.

Based around Apple's AVCam sample code.

Still needs some work.

Can be easily used in other project just copy VideoRecorder folder to your project. 

Add Camera View into you view controller 


       KZCameraView *cam = [[KZCameraView alloc]initWithFrame:self.view.frame withVideoPreviewFrame:CGRectMake(0.0, 0.0, 320.0, 320.0)];
       [self.view addSubview:cam];

Create a button (in example project bar button) to save recorded video.

       self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:cam action:@selector(saveVideo:)];

