//
//  QNNTcpPing.h
//  NetDiag
//
//  Created by bailong on 16/1/26.
//  Copyright © 2016年 Qiniu Cloud Storage. All rights reserved.
//
#import "QNNProtocols.h"
#import <Foundation/Foundation.h>

@interface QNNTcpPingResult : NSObject

@property (readonly) NSInteger code;
@property (readonly) NSString* ip;
@property (readonly) NSTimeInterval maxTime;
@property (readonly) NSTimeInterval minTime;
@property (readonly) NSTimeInterval avgTime;
@property (readonly) NSInteger loss;
@property (readonly) NSInteger count;
@property (readonly) NSTimeInterval totalTime;
@property (readonly) NSTimeInterval stddev;

- (NSString*)description;

@end

typedef void (^QNNTcpPingCompleteHandler)(QNNTcpPingResult*);

@interface QNNTcpPing : NSObject <QNNStopDelegate>

+ (instancetype)start:(NSString*)host
             complete:(QNNTcpPingCompleteHandler)complete;

+ (instancetype)start:(NSString*)host
                 port:(NSUInteger)port
                count:(NSInteger)count
             complete:(QNNTcpPingCompleteHandler)complete;

@end

