
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
		
		self.modalPresentationStyle = UIModalPresentationPageSheet;
		self.extendedLayoutIncludesOpaqueBars = YES;
	}
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor blackColor];
	
	_navigationBar = [[UINavigationBar alloc] init];
	UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:@""];
	item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didSelectCancelButton)];
	[_navigationBar setItems:@[item]];
	_navigationBar.translucent = NO;
	_navigationBar.barTintColor = [UIColor blackColor];
	_navigationBar.tintColor = [UIColor whiteColor];
	_navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
	
	_webView = [[UIWebView alloc] init];
	[_webView loadRequest:[NSURLRequest requestWithURL:_initialURL]];
	
	[self.view addSubview:_navigationBar];
	[self.view addSubview:_webView];
	
	[self setNeedsStatusBarAppearanceUpdate];
}

-(void)viewWillLayoutSubviews
{
	[super viewWillLayoutSubviews];
	CGSize size = self.view.bounds.size;
	
	CGFloat statusBarHeight = 0;
	if(![UIApplication sharedApplication].statusBarHidden)
	{
		statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
	}
	
	CGFloat navOffset = 0;
	_navigationBar.frame = CGRectMake(0, statusBarHeight, size.width, 44);
	if(!_navigationBar.hidden)
	{
		navOffset = statusBarHeight+44;
	}
	
	_webView.frame = CGRectMake(0, navOffset, size.width, size.height-navOffset);
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
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
