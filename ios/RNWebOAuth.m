
#import "RNWebOAuth.h"
#import "RNWebOAuthViewController.h"

@implementation RNWebOAuth

RCT_EXPORT_MODULE()

+(NSDictionary*)decodeQueryString:(NSString*)queryString
{
	NSArray<NSString*>* parts = [queryString componentsSeparatedByString:@"&"];
	NSMutableDictionary* params = [NSMutableDictionary dictionary];
	for (NSString* part in parts)
	{
		NSString* escapedPart = [part stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];
		NSArray<NSString*>* expressionParts = [escapedPart componentsSeparatedByString:@"="];
		if(expressionParts.count != 2)
		{
			continue;
		}
		NSString* key = [expressionParts[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString* value = [expressionParts[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		params[key] = value;
	}
	return params;
}

+(NSDictionary*)responseFromURL:(NSURL*)url;
{
	if(url == nil)
	{
		return nil;
	}
	NSDictionary* queryParams = [self decodeQueryString:url.query];
	if(queryParams != nil && queryParams.count > 0)
	{
		return queryParams;
	}
	NSDictionary* fragmentParams = [self decodeQueryString:url.fragment];
	if(fragmentParams != nil && fragmentParams.count > 0)
	{
		return fragmentParams;
	}
	return [NSDictionary dictionary];
}

+(id)ID:(id)obj
{
	if(obj == nil)
	{
		return [NSNull null];
	}
	return obj;
}

-(UIViewController*)rootViewController
{
	return [UIApplication sharedApplication].keyWindow.rootViewController;
}

RCT_EXPORT_METHOD(performWebAuth:(NSDictionary*)options completion:(RCTResponseSenderBlock)completion)
{
	NSLog(@"performWebAuth");
	
	NSString* urlString = options[@"url"];
	NSURL* url = [NSURL URLWithString:urlString];
	NSString* redirectScheme = options[@"redirectScheme"];
	NSString* redirectHost = options[@"redirectHost"];
	NSNumber* useBrowser = options[@"useBrowser"];
	
	if(urlString != nil && url == nil)
	{
		NSLog(@"A malformed URL was passed to WebOAuth.performWebAuth");
		if(completion)
		{
			completion(@[ [NSNull null] ]);
		}
		return;
	}
	
	if(useBrowser != nil && useBrowser.boolValue)
	{
		//TODO use browser
		NSLog(@"The browser isn't supported right now");
		if(completion)
		{
			completion(@[ [NSNull null] ]);
		}
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			RNWebOAuthViewController* webViewController = [[RNWebOAuthViewController alloc] initWithURL:url scheme:redirectScheme host:redirectHost];
			[webViewController setCompletion:^(NSURL* url) {
				if(completion)
				{
					completion(@[ [self.class ID:[self.class responseFromURL:url]] ]);
				}
			}];
			[[self rootViewController] presentViewController:webViewController animated:YES completion:nil];
		});
	}
}

@end
  
