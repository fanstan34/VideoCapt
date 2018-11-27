//
//  VedioView.m
//  VideoCapt
//
//  Created by tangzhi on 2017/6/19.
//  Copyright © 2017年 tangzhi. All rights reserved.
//

#import "VedioView.h"
#import <VideoToolbox/VideoToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AAPLEAGLLayer.h"
const uint8_t KStartCode[4] = {0, 0, 0, 1};

@implementation VideoPacket
- (instancetype)initWithSize:(NSInteger)size
{
    self = [super init];
    self.buffer = malloc(size);
    self.size = size;
    
    return self;
}

-(void)dealloc
{
    free(self.buffer);
}
@end

@implementation VedioView
{    
    RmvVlickBlk rmvBlock;
    UIView *bkVw;
    NSInputStream *iptStrm;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    VTDecompressionSessionRef _deocderSession;
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    AAPLEAGLLayer *_glLayer;
    
    uint8_t *_buffer;
    NSInteger _bufferSize;
    NSInteger _bufferCap;
    CADisplayLink               *_myTimer;//贴图定时器
    dispatch_queue_t queue;

}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc
{
    NSLog(@"%s",__func__);
}

-(void)setH264FileName:(NSString *)h264FileName {
    if (_h264FileName != h264FileName) {
        _h264FileName = h264FileName;
    }
    _bufferSize = 0;
    _bufferCap = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].bounds.size.height * 3 * 4;
    _buffer = malloc(_bufferCap);
    iptStrm = [NSInputStream inputStreamWithFileAtPath:h264FileName];
    [iptStrm open];
    queue = dispatch_queue_create("timeQueue", NULL);
    dispatch_async(queue, ^{
        [self plueAct];
    });
}

- (void)plueAct {
    if (_myTimer == nil) {
        _myTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(decodeFile)];
        _myTimer.frameInterval = 1;
        [_myTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }
}


- (void)decodeFile {
    VideoPacket *vp = nil;
    vp = [self nextPacket];
    if(vp == nil) {
        free(_buffer);
        [iptStrm close];
        [_myTimer invalidate];
        _myTimer = nil;
        return ;
    }
    
    uint32_t nalSize = (uint32_t)(vp.size - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    vp.buffer[0] = *(pNalSize + 3);
    vp.buffer[1] = *(pNalSize + 2);
    vp.buffer[2] = *(pNalSize + 1);
    vp.buffer[3] = *(pNalSize);
    
    CVPixelBufferRef pixelBuffer = NULL;
    int nalType = vp.buffer[4] & 0x1F;
    switch (nalType) {
        case 0x05:
            NSLog(@"Nal type is IDR frame");
            if([self initH264Decoder]) {
                pixelBuffer = [self decode:vp.buffer withSize:vp.size];
            }
            break;
        case 0x07:
            NSLog(@"Nal type is SPS");
            _spsSize = vp.size - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, vp.buffer + 4, _spsSize);
            break;
        case 0x08:
            NSLog(@"Nal type is PPS");
            _ppsSize = vp.size - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, vp.buffer + 4, _ppsSize);
            break;
            
        default:
            NSLog(@"Nal type is B/P frame");
            pixelBuffer = [self decode:vp.buffer withSize:vp.size];
            break;
    }
    
    if(pixelBuffer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _glLayer.pixelBuffer = pixelBuffer;
            CVPixelBufferRelease(pixelBuffer);
        });
    }
    
    NSLog(@"Read Nalu size %ld", vp.size);
}


-(VideoPacket*)nextPacket
{
    if(_bufferSize < _bufferCap && iptStrm.hasBytesAvailable) {
        NSInteger readBytes = [iptStrm read:_buffer + _bufferSize maxLength:_bufferCap - _bufferSize];
        _bufferSize += readBytes;
    }
    
    if(memcmp(_buffer, KStartCode, 4) != 0) {
        return nil;
    }
    
    if(_bufferSize >= 5) {
        uint8_t *bufferBegin = _buffer + 4;
        uint8_t *bufferEnd = _buffer + _bufferSize;
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 0x01) {
                if(memcmp(bufferBegin - 3, KStartCode, 4) == 0) {
                    NSInteger packetSize = bufferBegin - _buffer - 3;
                    VideoPacket *vp = [[VideoPacket alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, _buffer, packetSize);
                    
                    memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);
                    _bufferSize -= packetSize;
                    
                    return vp;
                }
            }
            ++bufferBegin;
        }
    }
    
    return nil;
}

- (void)sltOprtRt:(RmvVlickBlk)block {
    if (rmvBlock != block) {
        rmvBlock = block;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    if (currentPoint.x < bkVw.frame.origin.x || currentPoint.x > bkVw.frame.origin.x + bkVw.frame.size.width || currentPoint.y < bkVw.frame.origin.y || currentPoint.y > bkVw.frame.origin.y + bkVw.frame.size.height) {
        free(_buffer);
        [iptStrm close];
        [_myTimer invalidate];
        _myTimer = nil;
        if (rmvBlock) {
            rmvBlock();
        }
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initVw];
    }
    return self;
}

- (void)initVw {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:.3];
    
    bkVw = [[UIView alloc]initWithFrame:CGRectMake(10, 50, self.frame.size.width - 20, self.frame.size.height - 100)];//(10, 50, self.frame.size.width - 20, self.frame.size.height - 100)
    bkVw.backgroundColor = [UIColor whiteColor];
    bkVw.layer.cornerRadius = 5;
    bkVw.layer.borderWidth = 1;
    bkVw.layer.borderColor = [UIColor colorWithWhite:.9 alpha:1].CGColor;
    bkVw.layer.masksToBounds = YES;
    [self addSubview:bkVw];
    
    _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:bkVw.bounds];
    [bkVw.layer addSublayer:_glLayer];
    
//    bkVw.transform = CGAffineTransformIdentity;
//    bkVw.transform = CGAffineTransformMakeRotation(M_PI/2);
//    bkVw.center = self.center;
}

-(CVPixelBufferRef)decode:(uint8_t *)buffef withSize:(NSInteger)size {
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)buffef, size,
                                                          kCFAllocatorNull,
                                                          NULL, 0, size,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}

-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        CFRelease(attrs);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
    }
    
    return YES;
}

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@end
