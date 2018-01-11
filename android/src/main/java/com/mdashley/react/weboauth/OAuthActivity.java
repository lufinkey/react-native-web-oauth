package com.mdashley.react.weboauth;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.webkit.WebView;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.WritableMap;

import java.util.Set;

public class OAuthActivity extends Activity implements OAuthWebViewClientListener
{
	static Callback authCompletion;
	private Callback completion;
	private WritableMap response;

	@Override
	protected void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.oauth_layout);

		completion = authCompletion;
		authCompletion = null;
		response = null;

		WebView webView = (WebView)findViewById(R.id.oauth_webview);

		Intent intent = getIntent();
		String redirectScheme = intent.getStringExtra("redirectScheme");
		String redirectHost = intent.getStringExtra("redirectHost");
		OAuthWebViewClient webViewClient = new OAuthWebViewClient(redirectScheme, redirectHost, this);
		webView.setWebViewClient(webViewClient);

		String url = intent.getStringExtra("url");
		System.out.println("loading url "+url);
		webView.getSettings().setJavaScriptEnabled(true);
		webView.loadUrl(url);
	}

	public boolean onCreateOptionsMenu(Menu menu)
	{
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.oauth_menu, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item)
	{
		if (item.getItemId() == R.id.action_cancel)
		{
			finish();
			return true;
		}
		else
		{
			return super.onOptionsItemSelected(item);
		}
	}

	@Override
	public void onIntendedURIReached(Uri uri)
	{
		response = Arguments.createMap();
		Set<String> params = uri.getQueryParameterNames();
		for (String param : params)
		{
			response.putString(param, uri.getQueryParameter(param));
		}
		finish();
	}

	@Override
	protected void onDestroy()
	{
		super.onDestroy();
		if(isFinishing())
		{
			if(completion != null)
			{
				completion.invoke(response);
			}
		}
	}
}
