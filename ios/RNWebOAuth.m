
#import "RNWebOAuth.h"
#import "RNWebOAuthViewController.h"
#import <SafariServices/SafariServices.h>


NSString* const RNWebOAuthErrorDomain = @"RNWebOAuthErrorDomain";

@interface RNWebOAuth() <SFSafariViewControllerDelegate>
{
	SFAuthenticationSession* _sfAuthSession;
	SFSafariViewController* _safariViewController;
	__strong void(^_safariCloseHandler)();
	NSString* _safariRedirectScheme;
	NSString* _safariRedirectHost;
	NSURL* _safariResponseURL;
}
@end

@implementation RNWebOAuth

static RNWebOAuth* RNWebOAuth_currentSafariModule;

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

+(id)response:(NSURL*)url;
{
	if(url == nil)
	{
		return [NSNull null];
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
	NSString* urlString = options[@"url"];
	NSURL* url = [NSURL URLWithString:urlString];
	NSString* redirectScheme = options[@"redirectScheme"];
	NSString* redirectHost = options[@"redirectHost"];
	NSNumber* useBrowser = options[@"useBrowser"];
	
	if(urlString != nil && url == nil)
	{
		NSLog(@"A malformed URL was passed to WebOAuth.performWebAuth");
		if(completion != nil)
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
					if(completion != nil)
					{
						completion(@[ [NSNull null], [self.class ID:[self.class errorWithCode:RNWebOAuthErrorCodeMultipleSessions message:@"Cannot perform multiple oauth sessions at the same time"]] ]);
					}
					return;
				}
				
				UIViewController* topController = [self topViewController];
				BOOL originalUserInteractionEnabled = topController.view.userInteractionEnabled;
				topController.view.userInteractionEnabled = NO;
				
				_sfAuthSession = [[SFAuthenticationSession alloc] initWithURL:url callbackURLScheme:redirectScheme completionHandler:^(NSURL* url, NSError* error) {
					if(!topController.view.userInteractionEnabled)
					{
						topController.view.userInteractionEnabled = originalUserInteractionEnabled;
					}
					_sfAuthSession = nil;
					
					if(completion != nil)
					{
						completion(@[ [self.class response:url], [self.class error:error] ]);
					}
				}];
				
				[_sfAuthSession start];
			}
			else
			{
				if(RNWebOAuth_currentSafariModule != nil || _safariViewController != nil)
				{
					if(completion != nil)
					{
						completion(@[ [NSNull null], [self.class ID:[self.class errorWithCode:RNWebOAuthErrorCodeMultipleSessions message:@"Cannot perform multiple oauth sessions at the same time"]] ]);
					}
					return;
				}
			
				_safariRedirectScheme = redirectScheme;
				_safariRedirectHost = redirectHost;
				_safariViewController = [[SFSafariViewController alloc] initWithURL:url];
				_safariViewController.delegate = self;
			
				RNWebOAuth_currentSafariModule = self;
			
				__weak RNWebOAuth* weakSelf = self;
				_safariCloseHandler = ^() {
					RNWebOAuth* _self = weakSelf;
					NSURL* responseURL = _self->_safariResponseURL;
					
					RNWebOAuth_currentSafariModule = nil;
					_self->_safariCloseHandler = nil;
					_self->_safariViewController = nil;
					_self->_safariRedirectScheme = nil;
					_self->_safariRedirectHost = nil;
					_self->_safariResponseURL = nil;
					
					if(completion != nil)
					{
						completion(@[ [_self.class response:responseURL], [NSNull null] ]);
					}
				};
				
				[[self topViewController] showViewController:_safariViewController sender:nil];
			}
		}
		else
		{
			RNWebOAuthViewController* webViewController = [[RNWebOAuthViewController alloc] initWithURL:url scheme:redirectScheme host:redirectHost];
			[webViewController setCompletion:^(NSURL* url, NSError* error) {
				if(completion != nil)
				{
					completion(@[ [self.class response:url], [self.class error:error] ]);
				}
			}];
			[[self topViewController] showViewController:_safariViewController sender:nil];
		}
	});
}

+(BOOL)application:(UIApplication*)application openURL:(NSURL*)url
{
	if(RNWebOAuth_currentSafariModule != nil)
	{
		RNWebOAuth* webOAuth = RNWebOAuth_currentSafariModule;
		
		NSMutableString* pathStr = [NSMutableString stringWithString:@"/"];
		if(webOAuth->_safariRedirectHost != nil)
		{
			[pathStr appendString:webOAuth->_safariRedirectHost];
		}
		
		if([url.scheme isEqualToString:webOAuth->_safariRedirectScheme]
		   && ([url.host isEqualToString:webOAuth->_safariRedirectHost]
			   || ((url.host == nil || url.host.length == 0) && [url.path isEqualToString:pathStr])))
		{
			RNWebOAuth_currentSafariModule = nil;
			webOAuth->_safariResponseURL = url;
			dispatch_async(dispatch_get_main_queue(), ^{
				SFSafariViewController* safariController = webOAuth->_safariViewController;
				if(safariController != nil)
				{
					[safariController dismissViewControllerAnimated:YES completion:^{
						void(^closeHandler)() = webOAuth->_safariCloseHandler;
						closeHandler();
					}];
				}
			});
			return YES;
		}
	}
	return NO;
}

-(void)safariViewControllerDidFinish:(SFSafariViewController*)controller
{
	RNWebOAuth_currentSafariModule = nil;
	if(_safariCloseHandler != nil)
	{
		void(^closeHandler)() = _safariCloseHandler;
		closeHandler();
	}
}

@end
  
