
#import "RNWebOAuth.h"
#import "RNWebOAuthViewController.h"
#import <SafariServices/SafariServices.h>


NSString* const RNWebOAuthErrorDomain = @"RNWebOAuthErrorDomain";

@interface RNWebOAuth() <SFSafariViewControllerDelegate>
{
	SFAuthenticationSession* _sfAuthSession;
	SFSafariViewController* _safariViewController;
	NSString* _redirectScheme;
	NSString* _redirectHost;
}
@end

@implementation RNWebOAuth

static BOOL(^RNWebOAuth_urlHandler)(NSURL* url) = nil;

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

+(id)error:(NSError*)error
{
	if(error==nil)
	{
		return [NSNull null];
	}
	NSDictionary* fields = error.userInfo[@"jsFields"];
	NSMutableDictionary* obj = nil;
	if(fields!=nil)
	{
		obj = fields.mutableCopy;
	}
	else
	{
		obj = [NSMutableDictionary dictionary];
	}
	obj[@"domain"] = error.domain;
	obj[@"code"] = @(error.code);
	obj[@"message"] = error.localizedDescription;
	return obj;
}

+(NSError*)errorWithCode:(RNWebOAuthErrorCode)code message:(NSString*)message
{
	return [NSError errorWithDomain:RNWebOAuthErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey: message }];
}

-(UIViewController*)topViewController
{
	UIViewController* topController = [UIApplication sharedApplication].keyWindow.rootViewController;
	while(topController.presentedViewController != nil)
	{
		topController = topController.presentedViewController;
	}
	return topController;
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

	dispatch_async(dispatch_get_main_queue(), ^{
		if(useBrowser != nil && useBrowser.boolValue)
		{
			if (@available(iOS 11.0, *))
			{
				if(_sfAuthSession != nil)
				{
					if(completion)
					{
						completion(@[ [NSNull null], [self.class ID:[self.class errorWithCode:RNWebOAuthErrorCodeMultipleSessions message:@"Cannot perform multiple oauth sessions at the same time"]] ]);
					}
					return;
				}
				_sfAuthSession = [[SFAuthenticationSession alloc] initWithURL:url callbackURLScheme:redirectScheme completionHandler:^(NSURL* url, NSError* error) {
					_sfAuthSession = nil;
					if(completion)
					{
						completion(@[ [self.class ID:[self.class responseFromURL:url]], [self.class error:error] ]);
					}
				}];
				[_sfAuthSession start];
			}
			else
			{
				if(RNWebOAuth_urlHandler != nil || _safariViewController != nil)
				{
					if(completion)
					{
						completion(@[ [NSNull null], [self.class ID:[self.class errorWithCode:RNWebOAuthErrorCodeMultipleSessions message:@"Cannot perform multiple oauth sessions at the same time"]] ]);
					}
					return;
				}
				_safariViewController = [[SFSafariViewController alloc] initWithURL:url];
				_safariViewController.delegate = self;
				
				RNWebOAuth_urlHandler = ^BOOL(NSURL* url) {
					if(url == nil || ([url.scheme isEqualToString:_redirectScheme] && [url.host isEqualToString:_redirectHost]))
					{
						RNWebOAuth_urlHandler = nil;
						[_safariViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
							_safariViewController = nil;
							_redirectScheme = nil;
							_redirectHost = nil;
							if(completion)
							{
								completion(@[ [self.class ID:[self.class responseFromURL:url]], [NSNull null] ]);
							}
						}];
						return YES;
					}
					return NO;
				};
				
				[[self topViewController] presentViewController:_safariViewController animated:YES completion:nil];
			}
		}
		else
		{
			RNWebOAuthViewController* webViewController = [[RNWebOAuthViewController alloc] initWithURL:url scheme:redirectScheme host:redirectHost];
			[webViewController setCompletion:^(NSURL* url, NSError* error) {
				if(completion)
				{
					completion(@[ [self.class ID:[self.class responseFromURL:url]], [self.class error:error] ]);
				}
			}];
			[[self topViewController] presentViewController:webViewController animated:YES completion:nil];
		}
	});
}

+(BOOL)application:(UIApplication*)application openURL:(NSURL*)url
{
	if(RNWebOAuth_urlHandler != nil)
	{
		return RNWebOAuth_urlHandler(url);
	}
	return NO;
}

-(void)safariViewControllerDidFinish:(SFSafariViewController*)controller
{
	if(RNWebOAuth_urlHandler != nil)
	{
		RNWebOAuth_urlHandler(nil);
	}
}

@end
  
