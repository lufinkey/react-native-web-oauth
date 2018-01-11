package com.mdashley.react.weboauth;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.customtabs.CustomTabsCallback;
import android.support.customtabs.CustomTabsClient;
import android.support.customtabs.CustomTabsIntent;
import android.support.customtabs.CustomTabsServiceConnection;
import android.support.customtabs.CustomTabsSession;
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
	private boolean useBrowser;
	private WritableMap response;

	@Override
	protected void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);

		completion = authCompletion;
		authCompletion = null;
		response = null;

		Intent intent = getIntent();
		final String url = intent.getStringExtra("url");
		String redirectScheme = intent.getStringExtra("redirectScheme");
		String redirectHost = intent.getStringExtra("redirectHost");
		useBrowser = intent.getBooleanExtra("useBrowser", false);

		if(useBrowser)
		{
			final CustomTabsServiceConnection connection = new CustomTabsServiceConnection() {
				@Override
				public void onCustomTabsServiceConnected(ComponentName componentName, CustomTabsClient client) {
					CustomTabsSession session = client.newSession(new CustomTabsCallback() {
						@Override
						public void onNavigationEvent(int event, Bundle extras)
						{
							super.onNavigationEvent(event, extras);
						}
					});
					final CustomTabsIntent.Builder builder = new CustomTabsIntent.Builder();
					final CustomTabsIntent intent = builder.build();
					client.warmup(0L); // This prevents backgrounding after redirection
					intent.launchUrl(OAuthActivity.this, Uri.parse(url));
				}
				@Override
				public void onServiceDisconnected(ComponentName name) {}
			};
			CustomTabsClient.bindCustomTabsService(this, "com.android.chrome", connection);

			/*CustomTabsIntent.Builder builder = new CustomTabsIntent.Builder();
			CustomTabsIntent chromeIntent = builder.build();
			chromeIntent.launchUrl(this, Uri.parse(url));*/
		}
		else
		{
			setContentView(R.layout.oauth_layout);
			WebView webView = (WebView) findViewById(R.id.oauth_webview);

			OAuthWebViewClient webViewClient = new OAuthWebViewClient(redirectScheme, redirectHost, this);
			webView.setWebViewClient(webViewClient);

			System.out.println("loading url " + url);
			webView.getSettings().setJavaScriptEnabled(true);
			webView.loadUrl(url);
		}
	}

	public boolean onCreateOptionsMenu(Menu menu)
	{
		if(useBrowser)
		{
			return super.onCreateOptionsMenu(menu);
		}
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.oauth_menu, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item)
	{
		if(useBrowser)
		{
			return super.onOptionsItemSelected(item);
		}
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
	protected void onActivityResult(int requestCode, int resultCode, Intent intent)
	{
		Uri uri = intent.getData();
		System.out.println("got uri: "+uri.toString());
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
