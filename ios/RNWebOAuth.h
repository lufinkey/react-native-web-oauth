
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

#import <UIKit/UIKit.h>

extern NSString* const RNWebOAuthErrorDomain;

typedef enum
{
	//! Multiple OAuth logins are happening at once
	RNWebOAuthErrorCodeMultipleSessions = 100,
} RNWebOAuthErrorCode;

@interface RNWebOAuth : NSObject <RCTBridgeModule>

-(void)performWebAuth:(NSDictionary*)options completion:(RCTResponseSenderBlock)completion;

+(BOOL)application:(UIApplication*)application openURL:(NSURL*)url;

@end

