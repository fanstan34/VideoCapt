//
//  VTCEcd.m
//  VideoCapt
//
//  Created by tangzhi on 17/4/12.
//  Copyright © 2017年 tangzhi. All rights reserved.
//

#import "VTCEcd.h"

@implementation VTCEcd

{
    VTCompressionSessionRef _encodeSesion;
    dispatch_queue_t delegateQueue;
    NSFileHandle *fileHandle;
    dispatch_queue_t _encodeQueue;
    int frmCount;
}

//初始化编码参数
- (int)startEncodeSession:(float)width height:(float)height framerate:(int)fps bitrate:(int)bt {
    OSStatus status;
    VTCompressionOutputCallback cb = encodeOutputCallback;
    status = VTCompressionSessionCreate(kCFAllocatorDefault, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, cb, (__bridge void *)(self), &_encodeSesion);
    
    if (status != noErr) {
        NSLog(@"VTCompressionSessionCreate failed. ret=%d", (int)status);
        return -1;
    }
    
    // 设置实时编码输出，降低编码延迟
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    NSLog(@"set realtime  return: %d", (int)status);
    
    // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    NSLog(@"set profile   return: %d", (int)status);
    
    // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
    status  = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bt*3*4*8)); // bps
    status += VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bt*3*4), @1]); // Bps
    NSLog(@"set bitrate   return: %d", (int)status);
    
    // 设置关键帧间隔，即gop size
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(fps));
    
    // 设置帧率，只用于初始化session，不是实际FPS
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(fps));
    NSLog(@"set framerate return: %d", (int)status);
    // 开始编码
    status = VTCompressionSessionPrepareToEncodeFrames(_encodeSesion);
    // Set the properties
    
    NSLog(@"start encode  return: %d", (int)status);
    return 0;
}

// 编码一帧图像，使用queue，防止阻塞系统摄像头采集线程
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        frmCount ++;
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CMTime presentationTimeStamp = CMTimeMake(frmCount, 1000);//CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        CMTime duration = CMSampleBufferGetOutputDuration(sampleBuffer);
        
        NSDictionary *properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
        
        OSStatus status = VTCompressionSessionEncodeFrame(_encodeSesion, pixelBuffer, presentationTimeStamp, duration, (__bridge CFDictionaryRef)properties, pixelBuffer, NULL);
        if (status != noErr) {
            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)status);
            [self stopEncodeSession];
        }
    });
}

- (void)encodeSps:(NSData*)sps Pps:(NSData*)pps
{
    if (fileHandle == NULL) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *createPath = [NSString stringWithFormat:@"%@/vedio", documentsDirectory];
        // 判断文件夹是否存在，如果不存在，则创建
        if (![[NSFileManager defaultManager] fileExistsAtPath:createPath]) {
            [fileManager createDirectoryAtPath:createPath withIntermediateDirectories:YES attributes:nil error:nil];
        } else {
            NSLog(@"FileDir is exists.");
        }
        
        NSDate *date = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateFormat:@"YYYYMMdd-HHmmss"];
        NSString *h264Path = [NSString stringWithFormat:@"%@.h264",[formatter stringFromDate:date]];
        
        NSString *h264File = [createPath stringByAppendingPathComponent:h264Path];
        BOOL bl = [fileManager removeItemAtPath:h264File error:nil];
        bl = [fileManager createFileAtPath:h264File contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:h264File];
    }

    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
    [fileHandle writeData:byteHeader];
    [fileHandle writeData:sps];
    [fileHandle writeData:byteHeader];
    [fileHandle writeData:pps];

}

- (void)encodeData:(NSData*)data bKeyframe:(BOOL)keyframe Times:(double)times
{
    if (fileHandle != NULL) {
        
        const char bytes[]= "\x00\x00\x00\x01";
        size_t lenght = (sizeof bytes) - 1;
        NSData *byteHeader = [NSData dataWithBytes:bytes length:lenght];
        [fileHandle writeData:byteHeader];
        [fileHandle writeData:data];
    }
}

- (void) stopEncodeSession
{
    if (_encodeSesion) {
        VTCompressionSessionCompleteFrames(_encodeSesion, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_encodeSesion);
        CFRelease(_encodeSesion);
        _encodeSesion = NULL;
    }
}


static void encodeOutputCallback(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    if (status != noErr)
        return;
    
    if (sampleBuffer == nil) {
        return ;
    }
    VTCEcd *compressionSession = (__bridge VTCEcd *)VTref;
    
    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    if (keyframe)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0 );
        if (statusCode == noErr)
        {
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
            if (statusCode == noErr)
            {
                NSData *sps;
                NSData *pps;
                sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                
                [compressionSession encodeSps:sps Pps:pps];
            }
        }
    }
    
    CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    double dPTS = (double)(presentationTimeStamp.value) / presentationTimeStamp.timescale;
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            
            // Read the NAL unit length
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData* data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            [compressionSession encodeData:data bKeyframe:keyframe Times:dPTS];
            
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
        
    }
}

@end
