// Generated by Scapix Language Bridge
// https://www.scapix.com

#import "scapix/bridge/objc/BridgeObject.h"

NS_ASSUME_NONNULL_BEGIN

@class WSNetHttpRequest;
@class WSNetCancelableCallback;

@interface WSNetHttpNetworkManager : BridgeObject

-(WSNetHttpRequest*)createGetRequest:(NSString*)url timeoutMs:(uint16_t)timeoutMs isIgnoreSslErrors:(BOOL)isIgnoreSslErrors;
-(WSNetHttpRequest*)createPostRequest:(NSString*)url timeoutMs:(uint16_t)timeoutMs data:(NSString*)data isIgnoreSslErrors:(BOOL)isIgnoreSslErrors;
-(WSNetHttpRequest*)createPutRequest:(NSString*)url timeoutMs:(uint16_t)timeoutMs data:(NSString*)data isIgnoreSslErrors:(BOOL)isIgnoreSslErrors;
-(WSNetHttpRequest*)createDeleteRequest:(NSString*)url timeoutMs:(uint16_t)timeoutMs isIgnoreSslErrors:(BOOL)isIgnoreSslErrors;
-(WSNetCancelableCallback*)executeRequest:(WSNetHttpRequest*)request requestId:(uint64_t)requestId finishedCallback:(void(^)(unsigned long long, unsigned int, int, NSString*))finishedCallback;
-(WSNetCancelableCallback*)executeRequestEx:(WSNetHttpRequest*)request requestId:(uint64_t)requestId finishedCallback:(void(^)(unsigned long long, unsigned int, int, NSString*))finishedCallback progressCallback:(void(^)(unsigned long long, unsigned long long, unsigned long long))progressCallback readyDataCallback:(void(^)(unsigned long long, NSString*))readyDataCallback;
-(void)setProxySettings:(NSString*)address username:(NSString*)username password:(NSString*)password;
-(WSNetCancelableCallback*)setWhitelistIpsCallback:(void(^)(NSOrderedSet<NSString*>*))whitelistIpsCallback;
-(WSNetCancelableCallback*)setWhitelistSocketsCallback:(void(^)(NSOrderedSet<NSNumber*>*))whitelistSocketsCallback;

@end

NS_ASSUME_NONNULL_END