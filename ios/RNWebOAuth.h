
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

@interface RNWebOAuth : NSObject <RCTBridgeModule>

-(void)performWebAuth:(NSDictionary*)options completion:(RCTResponseSenderBlock)completion;

@end

