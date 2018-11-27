//
//  ViewController.m
//  VideoCapt
//
//  Created by tangzhi on 17/4/12.
//  Copyright © 2017年 tangzhi. All rights reserved.
//

#import "ViewController.h"
#import "VideoTable.h"
#import "VedioCaptViewCtr.h"
#import "EncodeAudioViewController.h"

//typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface ViewController ()
{
//    AVCaptureSession *session;
//    
//    UIView *showVw;
//    
//    VTCompressionSessionRef _encodeSesion;
//    
//    AVCaptureDeviceInput *capDeviceInput;//负责从AVCaptureDevice获得输入数据
//    
////    NSMutableData *_data;
////    NSString *h264File;
////    NSFileHandle *fileHandle;
//    
//    AVCaptureConnection* _videoConnection;
//    VTCEcd *vtcEcd;
    
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIView *navGtVw = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    navGtVw.backgroundColor = [UIColor colorWithRed:63/255.0 green:186/255.0 blue:250/255.0 alpha:1];
    [self.view addSubview:navGtVw];
    
    UIView *ln = [[UIView alloc]initWithFrame:CGRectMake(0, 63, self.view.frame.size.width, 1)];
    ln.backgroundColor = [UIColor blackColor];
    ln.layer.borderWidth = 0;
    [self.view addSubview:ln];
    
    NSArray *ary = @[@"视频列表",@"视频录制",@"音频列表",@"音频录制"];
    for (int i = 0; i < 4; i++) {
        UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/4*i, 64, self.view.frame.size.width/4, self.view.frame.size.width/4)];
        btn.tag = 10 + i;
        [btn setTitle:ary[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [UIColor grayColor].CGColor;
        [btn addTarget:self action:@selector(btnAct:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}

- (void)btnAct:(UIButton *)btn {
    if (btn.tag == 10) {
        [self presentViewController:[VideoTable new] animated:YES completion:nil];
    } else if(btn.tag == 11){
        [self presentViewController:[VedioCaptViewCtr new] animated:YES completion:nil];
    } else if (btn.tag == 13) {
        [self presentViewController:[EncodeAudioViewController new] animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
