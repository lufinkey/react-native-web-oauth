
package com.mdashley.react.weboauth;

import android.app.Activity;
import android.content.Intent;
import android.telecom.Call;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableMap;
import com.lufinkey.react.weboauth.OAuthActivity;

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
		mainActivity.startActivity(new Intent(mainActivity, OAuthActivity.class));
	}
}
