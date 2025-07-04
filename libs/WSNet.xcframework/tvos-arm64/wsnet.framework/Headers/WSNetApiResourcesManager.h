// Generated by Scapix Language Bridge
// https://www.scapix.com

#import "scapix/bridge/objc/BridgeObject.h"

NS_ASSUME_NONNULL_BEGIN

@class WSNetCancelableCallback;
@class WSNetServerAPI;

@interface WSNetApiResourcesManager : BridgeObject

-(WSNetCancelableCallback*)setCallback:(void(^)(int, int, NSString*))callback;
-(void)setAuthHash:(NSString*)authHash;
-(BOOL)isExist;
-(BOOL)loginWithAuthHash;
-(void)authTokenLogin:(BOOL)useAsciiCaptcha;
-(void)login:(NSString*)username password:(NSString*)password code2fa:(NSString*)code2fa secureToken:(NSString*)secureToken captchaSolution:(NSString*)captchaSolution captchaTrailX:(NSArray<NSNumber*>*)captchaTrailX captchaTrailY:(NSArray<NSNumber*>*)captchaTrailY;
-(void)logout;
-(void)fetchSession;
-(void)fetchServerCredentials;
-(NSString*)authHash;
-(void)removeFromPersistentSettings;
-(void)checkUpdate:(int)channel appVersion:(NSString*)appVersion appBuild:(NSString*)appBuild osVersion:(NSString*)osVersion osBuild:(NSString*)osBuild;
-(void)setNotificationPcpid:(NSString*)pcpid;
-(void)setMobileDeviceId:(NSString*)appleId gpDeviceId:(NSString*)gpDeviceId;
-(NSString*)sessionStatus;
-(NSString*)portMap;
-(NSString*)locations;
-(NSString*)staticIps;
-(NSString*)serverCredentialsOvpn;
-(NSString*)serverCredentialsIkev2;
-(NSString*)serverConfigs;
-(NSString*)notifications;
-(NSString*)checkUpdate;
-(NSString*)authTokenLoginResult;
-(void)setUpdateIntervals:(int)sessionInDisconnectedStateMs sessionInConnectedStateMs:(int)sessionInConnectedStateMs locationsMs:(int)locationsMs staticIpsMs:(int)staticIpsMs serverConfigsAndCredentialsMs:(int)serverConfigsAndCredentialsMs portMapMs:(int)portMapMs notificationsMs:(int)notificationsMs checkUpdateMs:(int)checkUpdateMs;

@end

NS_ASSUME_NONNULL_END
