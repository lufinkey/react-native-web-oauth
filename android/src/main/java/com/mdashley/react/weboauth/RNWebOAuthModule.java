
package com.mdashley.react.weboauth;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.support.customtabs.CustomTabsIntent;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableMap;

public class RNWebOAuthModule extends ReactContextBaseJavaModule
{
	private final ReactApplicationContext reactContext;

	public RNWebOAuthModule(ReactApplicationContext reactContext)
	{
		super(reactContext);
		this.reactContext = reactContext;
	}

	@Override
	public String getName()
	{
		return "RNWebOAuth";
	}

	@ReactMethod
	public void login(ReadableMap options, final Callback callback)
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

	@ReactMethod
	public void handleURL(String url)
	{
		System.out.println("handleURL: "+url);
	}
}
