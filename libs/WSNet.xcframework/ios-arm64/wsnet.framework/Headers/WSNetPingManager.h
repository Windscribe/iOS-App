// Generated by Scapix Language Bridge
// https://www.scapix.com

#import "scapix/bridge/objc/BridgeObject.h"

NS_ASSUME_NONNULL_BEGIN

@class WSNetCancelableCallback;

@interface WSNetPingManager : BridgeObject

-(WSNetCancelableCallback*)ping:(NSString*)ip hostname:(NSString*)hostname pingType:(int)pingType callback:(void(^)(NSString*, BOOL, int, BOOL))callback;

@end

NS_ASSUME_NONNULL_END