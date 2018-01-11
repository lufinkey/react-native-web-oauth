
import { NativeModules } from 'react-native';

const WebOAuth = NativeModules.RNWebOAuth;

WebOAuth.login = function(options, callback)
{
	WebOAuth.performWebAuth(options, (response) => {
		if(callback)
		{
			callback(response);
		}
	});
}

export default WebOAuth;
