//
//  VedioView.h
//  VideoCapt
//
//  Created by tangzhi on 2017/6/19.
//  Copyright © 2017年 tangzhi. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^RmvVlickBlk)();

@interface VideoPacket : NSObject

@property uint8_t* buffer;
@property NSInteger size;

@end

@interface VedioView : UIView
@property(nonatomic,copy)NSString *h264FileName;

- (void)sltOprtRt:(RmvVlickBlk)block;
@end
