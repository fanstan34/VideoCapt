//
//  VedioCaptViewCtr.m
//  VideoCapt
//
//  Created by tangzhi on 17/4/13.
//  Copyright © 2017年 tangzhi. All rights reserved.
//

#import "VedioCaptViewCtr.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <VideoToolbox/VideoToolbox.h>
#import "VTCEcd.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface VedioCaptViewCtr ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureSession *session;
    VTCompressionSessionRef _encodeSesion;
    UIView *showVw;

    AVCaptureDeviceInput *capDeviceInput;//负责从AVCaptureDevice获得输入数据
    
    AVCaptureConnection* _videoConnection;
    VTCEcd *vtcEcd;
    
    AVCaptureDevice *captDevice; //设备摄像头
    
    AVCaptureVideoDataOutput *outputDevice;  //输出设备
    
    UIButton *lzVideoBtn;
    
    BOOL isSave;
    
    NSTimer *timer;
    
    int iTm;
    
    UILabel *timeLb;
}

@end

@implementation VedioCaptViewCtr

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor grayColor];
    
    showVw = [[UIView alloc]initWithFrame:self.view.bounds];
    showVw.backgroundColor = [UIColor grayColor];
    [self.view addSubview:showVw];
    
    UIView *navVw = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
    navVw.backgroundColor = [UIColor colorWithWhite:0 alpha:.3];
    [self.view addSubview:navVw];
    
    UIButton *cance = [[UIButton alloc]initWithFrame:CGRectMake(5, 7, 40, 25)];
    [cance setImage:[UIImage imageNamed:@"fanhui"] forState:UIControlStateNormal];
    [cance addTarget:self action:@selector(canceAct) forControlEvents:UIControlEventTouchUpInside];
    [navVw addSubview:cance];
    
    timeLb = [[UILabel alloc]initWithFrame:CGRectMake(35, 5, self.view.frame.size.width - 70, 30)];
    timeLb.textColor = [UIColor whiteColor];
    timeLb.text = @"00:00:00";
    timeLb.textAlignment = NSTextAlignmentCenter;
    [navVw addSubview:timeLb];
    
    UIView *czVw = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height - 100, self.view.frame.size.width, 100)];
    czVw.backgroundColor = [UIColor colorWithWhite:0 alpha:.3];
    [self.view addSubview:czVw];

    lzVideoBtn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width - 60)/2, 20, 60, 60)];
    lzVideoBtn.layer.cornerRadius = 30;
    lzVideoBtn.layer.masksToBounds = YES;
    lzVideoBtn.backgroundColor = [UIColor redColor];
    [czVw addSubview:lzVideoBtn];
    
    UIButton *lzLayBtn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width - 70)/2, 15, 70, 70)];
    lzLayBtn.layer.cornerRadius = 35;
    lzLayBtn.layer.masksToBounds = YES;
    lzLayBtn.backgroundColor = [UIColor clearColor];
    lzLayBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    [lzLayBtn addTarget:self action:@selector(lzSPVideo) forControlEvents:UIControlEventTouchUpInside];
    lzLayBtn.layer.borderWidth = 7;
    [czVw addSubview:lzLayBtn];
    
    UIButton *sxtBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sxtBtn.frame = CGRectMake(self.view.frame.size.width - 50, 30, 40, 40);
    [sxtBtn setImage:[UIImage imageNamed:@"14-视频模块-摄像头切换"] forState:UIControlStateNormal];
    [sxtBtn addTarget:self action:@selector(sxtAct) forControlEvents:UIControlEventTouchUpInside];
    [czVw addSubview:sxtBtn];
}

//录制视频
- (void)lzSPVideo {
    if (isSave) {
        lzVideoBtn.frame = CGRectMake((self.view.frame.size.width - 60)/2, 20, 60, 60);
        lzVideoBtn.layer.cornerRadius = 30;
        isSave = NO;
        timeLb.text = @"00:00:00";
    } else {
        if ([session canAddOutput:outputDevice]) {
            [session addOutput:outputDevice];
            _videoConnection = [outputDevice connectionWithMediaType:AVMediaTypeVideo];
            if ([_videoConnection isVideoOrientationSupported]) {
                _videoConnection.videoOrientation = [self getCaptureVideoOrientation];
            }
            isSave = NO;
            timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        } else {
            [timer invalidate];
            timer = nil;
            lzVideoBtn.frame = CGRectMake((self.view.frame.size.width - 40)/2, 30, 40, 40);
            lzVideoBtn.layer.cornerRadius = 5;
            isSave = YES;
            [session removeOutput:outputDevice];
        }
    }
}

- (void)timerAction {
    iTm ++;
    if (iTm < 60) {
        timeLb.text = [NSString stringWithFormat:@"00:00:%02d",iTm];
    } else if(iTm >= 60 && iTm<= 60*60) {
        timeLb.text = [NSString stringWithFormat:@"00:%02d:%02d",iTm/60,iTm%60];
    } else {
        timeLb.text = [NSString stringWithFormat:@"%02d:%02d:%02d",iTm/(60*60),iTm%(60*60)/60,iTm%60];
    }
}


- (AVCaptureVideoOrientation)getCaptureVideoOrientation {
    AVCaptureVideoOrientation result;
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            //如果这里设置成AVCaptureVideoOrientationPortraitUpsideDown，则视频方向和拍摄时的方向是相反的。
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            result = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            result = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            result = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    return result;
}

//摄像头切换
- (void)sxtAct {
    AVCaptureDevice *currentDevice=[capDeviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
//    [self removeNotificationFromCaptureDevice:currentDevice];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition=AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition=AVCaptureDevicePositionBack;
    }
    toChangeDevice=[self getCameraDeviceWithPosition:toChangePosition];
//    [self addNotificationToCaptureDevice:toChangeDevice];
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [session beginConfiguration];
    //移除原有输入对象
    [session removeInput:capDeviceInput];
    //添加新的输入对象
    if ([session canAddInput:toChangeDeviceInput]) {
        [session addInput:toChangeDeviceInput];
        capDeviceInput = toChangeDeviceInput;
    }
    //提交会话配置
    [session commitConfiguration];
}

- (void)canceAct {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    //    NSString * mediaType = AVMediaTypeVideo;
    //    AVAuthorizationStatus  authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    //    if (authorizationStatus == AVAuthorizationStatusRestricted|| authorizationStatus == AVAuthorizationStatusDenied) {
    //        UIAlertController * alertC = [UIAlertController alertControllerWithTitle:@"摄像头访问受限" message:nil preferredStyle:UIAlertControllerStyleAlert];
    //        [self presentViewController:alertC animated:YES completion:nil];
    //        UIAlertAction * action = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    //            [self dismissViewControllerAnimated:YES completion:nil];
    //        }];
    //        [alertC addAction:action];
    //    }else{
    //        NSLog(@"asdasdasd");
    //    }
    //
    //    return;
    
    session = [[AVCaptureSession alloc]init];
    if ([session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        session.sessionPreset=AVCaptureSessionPreset640x480;
    }
    //获得输入设备
    captDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];//取得前置摄像头
    if (!captDevice) {
        NSLog(@"取得前置摄像头时出现问题.");
        return;
    }
    NSError *error=nil;
    //根据输入设备初始化设备输入对象，用于获得输入数据
    capDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:captDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    if ([session canAddInput:capDeviceInput]) {
        [session addInput:capDeviceInput];
    }
    
    //初始化设备输出对象，用于获得输出数据
    outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    [outputDevice setAlwaysDiscardsLateVideoFrames:NO];
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* val = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:val forKey:key];
    [captDevice lockForConfiguration:&error];
    if (error == nil) {
        NSLog(@"cameraDevice.activeFormat.videoSupportedFrameRateRanges IS %@",[captDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0]);
        if (captDevice.activeFormat.videoSupportedFrameRateRanges){
            [captDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 20)];
            [captDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 20)];
        }
    }else{
    }
    [captDevice unlockForConfiguration];
    
    outputDevice.videoSettings = videoSettings;
    
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];


    //创建视频预览层，用于实时展示摄像头状态
    AVCaptureVideoPreviewLayer *capVideoPrvLy = [[AVCaptureVideoPreviewLayer alloc]initWithSession:session];
    
    CALayer *layer = showVw.layer;
    layer.masksToBounds=YES;
    
    capVideoPrvLy.frame=layer.bounds;
    capVideoPrvLy.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
    //将视频预览层添加到界面中
    [layer addSublayer:capVideoPrvLy];

    
    //初始化设备输出对象，用于获得输出数据
//    AVCaptureMovieFileOutput *captureMovieFileOutput=[[AVCaptureMovieFileOutput alloc]init];
//    captureMovieFileOutput.maxRecordedDuration = CMTimeMake(1, 20);
//    captureMovieFileOutput.minFreeDiskSpaceLimit = 0;
//    
//    if ([session canAddInput:captureMovieFileOutput]) {
//        [session addInput:captureMovieFileOutput];
////        _videoConnection = [outputDevice connectionWithMediaType:AVMediaTypeVideo];
////        if ([_videoConnection isVideoOrientationSupported])
////        {
////            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
////            [_videoConnection setVideoOrientation:orientation];
////        }
//        _videoConnection = [captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//        if ([_videoConnection isVideoStabilizationSupported ]) {
//            _videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
//            [_videoConnection setVideoOrientation:orientation];
//        }
//    }
    
    //    [layer insertSublayer:capVideoPrvLy below:self.focusCursor.layer];
    //    [self addNotificationToCaptureDevice:captureDevice];
    //    [self addGenstureRecognizer];
    
    vtcEcd = [[VTCEcd alloc]init];
    [vtcEcd startEncodeSession:self.view.frame.size.width height:self.view.frame.size.height framerate:10 bitrate:self.view.frame.size.width*self.view.frame.size.height];
    
}

-(AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections

{
    
    for ( AVCaptureConnection *connection in connections ) {
        
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            
            if ( [[port mediaType] isEqual:mediaType] ) {
                
                return connection;
                
            }
            
        }
        
    }
    
    return nil;
    
}


#pragma mark - sampleBuffer 数据
-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection

{
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    double dPTS = (double)(pts.value) / pts.timescale;
    
    NSLog(@"DPTS is %f",dPTS);
    
    if ([outputDevice isEqual:captureOutput]) {
        [vtcEcd encodeSampleBuffer:sampleBuffer];
    } else {
        //
        //        [aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
        //            if (encodedData) {
        //
        //                NSLog(@"Audio data (%lu): %@", (unsigned long)encodedData.length, encodedData.description);
        //
        //#pragma mark
        //#pragma mark -  音频数据(encodedData)
        //                [_data appendData:encodedData];
        //
        //
        //            } else {
        //                NSLog(@"Error encoding AAC: %@", error);
        //            }
        //        }];
        //
    }
    
}

//- (BOOL)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer forceKeyframe:(BOOL)forceKeyframe {
//    return YES;
//}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [session startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [session stopRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}


///**
// *  改变设备属性的统一操作方法
// *
// *  @param propertyChange 属性改变操作
// */
//-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
//    AVCaptureDevice *captureDevice= [capDeviceInput device];
//    NSError *error;
//    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
//    if ([captureDevice lockForConfiguration:&error]) {
//        propertyChange(captureDevice);
//        [captureDevice unlockForConfiguration];
//    }else{
//        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
//    }
//}
//
//
//
//#pragma mark - 通知
///**
// *  给输入设备添加通知
// */
//-(void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice{
//    //注意添加区域改变捕获通知必须首先设置设备允许捕获
//    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
//        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
//    }];
//    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
//    //捕获区域发生改变
//    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
//}
//-(void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice{
//    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
//    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
//}
///**
// *  移除所有通知
// */
//-(void)removeNotification{
//    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
//    [notificationCenter removeObserver:self];
//}
//
//-(void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession{
//    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
//    //会话出错
//    [notificationCenter addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
//}
//
///**
// *  捕获区域改变
// *
// *  @param notification 通知对象
// */
//-(void)areaChange:(NSNotification *)notification{
//    NSLog(@"捕获区域改变...");
//}

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
