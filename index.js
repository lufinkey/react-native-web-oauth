import { NativeModules } from 'react-native';
import QueryString from 'querystring';

const WebOAuth = NativeModules.RNWebOAuth;

WebOAuth.login = function(options, callback) {
	let authOptions = Object.assign({}, options);
	
	const params = authOptions.params;

	delete authOptions.params;
	delete authOptions.tokenSwapURL;
	delete authOptions.tokenRefreshURL;

	if (typeof params === 'object' && Object.keys(params).length > 0) {
		authOptions.url = authOptions.url + '?' + QueryString.stringify(params);
	}

	WebOAuth.performWebAuth(authOptions, (response) => {
		// TODO: Perform token swap
		if (callback) {
			callback(response);
		}
	});
}

export default WebOAuth;
