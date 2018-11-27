//
//  VTCEcd.h
//  VideoCapt
//
//  Created by tangzhi on 17/4/12.
//  Copyright © 2017年 tangzhi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface VTCEcd : NSObject
@property(nonatomic,assign)int spsppsFound;

- (int)startEncodeSession:(float)width height:(float)height framerate:(int)fps bitrate:(int)bt;
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end
