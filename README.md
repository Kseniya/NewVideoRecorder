VideoRecorder
================
Needs more work.

Vine like video recorder. Hold you finger - record, let it go - stop recording.
Ability to switch between front and back camera, plus deleting last recorded piece.

Based around Apple's AVCam sample code.


Can be imoported to other project by copying VideoRecorder folder. 
Add Camera View into you view controller 

        self.cam = [[KZCameraView alloc]initWithFrame:self.view.frame withVideoPreviewFrame:CGRectMake(0.0, 0.0, 320.0, 320.0)];
        [self.view addSubview:self.cam];
       
Set max duration of the video

       self.cam.maxDuration = 10.0;

Create a button (in example project bar button) to save recorded video.

       self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self. action:@selector(saveVideo:)];

Use saveVideoWithCompletionBlock: method to save the video and do something after it gets saved

    -(IBAction)saveVideo:(id)sender
    {
      [self.cam saveVideoWithCompletionBlock:^(BOOL success) {
        if (success)
        {
        //Do something after video got succesfully saved
        }
    }];
   }
