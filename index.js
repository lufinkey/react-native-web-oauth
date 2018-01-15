
import { NativeModules } from 'react-native';
import QueryString from 'querystring';

const WebOAuth = NativeModules.RNWebOAuth;

WebOAuth.login = function(options, callback)
{
	var authOptions = Object.assign({}, options);
	
	const params = authOptions.params;
	const tokenSwapURL = authOptions.tokenSwapURL;
	const tokenRefreshURL = authOptions.tokenRefreshURL;

	delete authOptions.params;
	delete authOptions.tokenSwapURL;
	delete authOptions.tokenRefreshURL;

	if(typeof params == 'object' && Object.keys(params).length > 0)
	{
		authOptions.url = authOptions.url+'?'+QueryString.stringify(params);
	}

	WebOAuth.performWebAuth(authOptions, (response) => {
		//TODO perform token swap
		if(callback)
		{
			callback(response);
		}
	});
}

export default WebOAuth;
