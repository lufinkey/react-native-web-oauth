
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef void(^RNWebOAuthResponseBlock)(NSURL*,NSError*);


@interface RNWebOAuthViewController : UIViewController <UIWebViewDelegate>

-(id)initWithURL:(NSURL*)url scheme:(NSString*)scheme host:(NSString*)host;

@property (strong, readonly) NSString* redirectScheme;
@property (strong, readonly) NSString* redirectHost;

@property (strong, readonly) UINavigationBar* navigationBar;
@property (strong, readonly) UIWebView* webView;

@property (strong) RNWebOAuthResponseBlock completion;

@end
