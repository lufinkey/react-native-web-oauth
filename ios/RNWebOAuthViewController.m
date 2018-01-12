
#import "RNWebOAuthViewController.h"

@interface RNWebOAuthViewController()
{
	NSURL* _initialURL;
	BOOL _completed;
}
@end

@implementation RNWebOAuthViewController

-(id)initWithURL:(NSURL*)url scheme:(NSString*)scheme host:(NSString*)host
{
	if(self = [super init])
	{
		_initialURL = url;
		_redirectScheme = scheme;
		_redirectHost = host;
		_completed = NO;
		_completion = nil;
	}
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	_webView = [[UIWebView alloc] init];
	[_webView loadRequest:[NSURLRequest requestWithURL:_initialURL]];
	
	UINavigationItem* navItem = [[UINavigationItem alloc] init];
	[navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
																   style:UIBarButtonItemStylePlain
																  target:self
																  action:@selector(didSelectCancelButton)]];
	_navigationBar = [[UINavigationBar alloc] init];
	
	[self.view addSubview:_navigationBar];
	[self.view addSubview:_webView];
}

-(void)viewWillLayoutSubviews
{
	[super viewWillLayoutSubviews];
	CGSize size = self.view.bounds.size;
	
	CGFloat navBarHeight = 44;
	if(![UIApplication sharedApplication].isStatusBarHidden)
	{
		navBarHeight += [UIApplication sharedApplication].statusBarFrame.size.height;
	}
	
	_navigationBar.frame = CGRectMake(0, 0, size.width, navBarHeight);
	_webView.frame = CGRectMake(0, navBarHeight, size.width, size.height);
}

-(void)didSelectCancelButton
{
	if(_completed)
	{
		return;
	}
	_completed = YES;
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		if(_completion != nil)
		{
			_completion(nil);
		}
	}];
}

-(BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	if([request.URL.scheme isEqualToString:_redirectScheme] && [request.URL.host isEqualToString:_redirectHost])
	{
		_completed = YES;
		[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
			_completion(request.URL);
		}];
		return NO;
	}
	return YES;
}

@end
