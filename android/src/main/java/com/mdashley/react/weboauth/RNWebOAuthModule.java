
package com.mdashley.react.weboauth;

import android.app.Activity;
import android.content.Intent;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableMap;

public class RNWebOAuthModule extends ReactContextBaseJavaModule implements ActivityEventListener
{
	private final ReactApplicationContext reactContext;

	public RNWebOAuthModule(ReactApplicationContext reactContext)
	{
		super(reactContext);
		this.reactContext = reactContext;

		reactContext.addActivityEventListener(this);
	}

	@Override
	public String getName()
	{
		return "RNWebOAuth";
	}

	@ReactMethod
	public void performWebAuth(ReadableMap options, final Callback callback)
	{
		Activity mainActivity = reactContext.getCurrentActivity();
		Intent intent = new Intent(mainActivity, OAuthActivity.class);
		intent.putExtra("url", options.getString("url"));
		intent.putExtra("redirectScheme", options.getString("redirectScheme"));
		intent.putExtra("redirectHost", options.getString("redirectHost"));
		if(options.hasKey("useBrowser"))
		{
			intent.putExtra("useBrowser", options.getBoolean("useBrowser"));
		}

		OAuthActivity.authCompletion = callback;

		mainActivity.startActivity(intent);
	}

	@Override
	public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data)
	{
		//
	}

	@Override
	public void onNewIntent(Intent intent)
	{
		if(OAuthActivity.currentActivity != null)
		{
			OAuthActivity.currentActivity.handleResponse(intent.getData());
		}
	}
}
