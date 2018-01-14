package com.mdashley.react.weboauth;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.customtabs.CustomTabsIntent;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.webkit.WebView;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.WritableMap;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.Set;

public class OAuthActivity extends Activity implements OAuthWebViewClientListener
{
	static OAuthActivity currentActivity = null;
	static Callback authCompletion = null;

	private Callback completion = null;

	private boolean useBrowser = false;
	private boolean browserIsOpen = false;
	private String browserRedirectScheme = "";
	private String browserRedirectHost = "";

	private WritableMap response = null;
	private boolean responded = false;

	private ProgressDialog progressDialog = null;

	void handleRequestIntent(Intent intent)
	{
		final String url = intent.getStringExtra("url");
		String redirectScheme = intent.getStringExtra("redirectScheme");
		String redirectHost = intent.getStringExtra("redirectHost");
		useBrowser = intent.getBooleanExtra("useBrowser", false);

		if(url == null || url.length() == 0)
		{
			System.out.println("A malformed URL was passed to OAuthActivity.handleRequestIntent");
			finish();
			return;
		}

		if(useBrowser)
		{
			browserRedirectScheme = redirectScheme;
			browserRedirectHost = redirectHost;

			CustomTabsIntent.Builder builder = new CustomTabsIntent.Builder();
			CustomTabsIntent chromeIntent = builder.build();
			chromeIntent.launchUrl(this, Uri.parse(url));
			browserIsOpen = true;
		}
		else
		{
			progressDialog.dismiss();

			setContentView(R.layout.oauth_layout);
			WebView webView = (WebView) findViewById(R.id.oauth_webview);

			OAuthWebViewClient webViewClient = new OAuthWebViewClient(redirectScheme, redirectHost, this);
			webView.setWebViewClient(webViewClient);

			webView.getSettings().setJavaScriptEnabled(true);
			webView.loadUrl(url);
		}
	}

	void handleResponse(Uri uri)
	{
		if(responded)
		{
			throw new IllegalStateException("Cannot handle response URI multiple times");
		}
		responded = true;

		if(uri == null)
		{
			response = null;
		}
		else
		{
			response = Arguments.createMap();
			Set<String> params = uri.getQueryParameterNames();
			if(params != null && params.size() > 0)
			{
				for(String param : params)
				{
					response.putString(param, uri.getQueryParameter(param));
				}
			}
			else
			{
				String hashQuery = uri.getEncodedFragment();
				hashQuery = hashQuery.replaceAll("\\+", "%20");
				String[] parts = hashQuery.split("&");
				for(int i=0; i<parts.length; i++)
				{
					String[] part = parts[i].split("=");
					if(part.length != 2)
					{
						continue;
					}
					try
					{
						String key = URLDecoder.decode(part[0], "utf-8");
						String value = URLDecoder.decode(part[1], "utf-8");
						response.putString(key, value);
					}
					catch (UnsupportedEncodingException e)
					{
						System.out.println("could not decode URI part: "+parts[i]);
					}
				}
			}
		}

		finish();
	}

	void handleURI(Uri uri)
	{
		if(uri == null)
		{
			return;
		}

		String pathStr = "/";
		if(browserRedirectHost != null)
		{
			pathStr += browserRedirectHost;
		}

		if(uri.getScheme().equals(browserRedirectScheme)
		   && ((browserRedirectHost != null && uri.getHost() != null && uri.getHost().equals(browserRedirectHost))
				|| (browserRedirectHost == null && uri.getHost() == null)
				|| ((uri.getHost() == null || uri.getHost().length() == 0) && uri.getPath().equals(pathStr))))
		{
			handleResponse(uri);
		}
	}

	@Override
	protected void onCreate(Bundle savedInstanceState)
	{
		if(currentActivity!=null)
		{
			throw new IllegalStateException("Cannot create multiple OAuthActivity instances at the same time");
		}

		super.onCreate(savedInstanceState);

		currentActivity = this;

		completion = authCompletion;
		authCompletion = null;
		response = null;

		progressDialog = new ProgressDialog(this);
		progressDialog.setMessage("Loading");
		progressDialog.setCancelable(false);
		progressDialog.show();
	}

	@Override
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
		return super.onOptionsItemSelected(item);
	}

	@Override
	protected void onResume()
	{
		super.onResume();
		if(browserIsOpen)
		{
			if(!isFinishing())
			{
				finish();
			}
		}
		else
		{
			handleRequestIntent(getIntent());
		}
	}

	@Override
	public void onIntendedURIReached(Uri uri)
	{
		handleResponse(uri);
	}

	@Override
	protected void onDestroy()
	{
		super.onDestroy();
		currentActivity = null;
		if(progressDialog.isShowing())
		{
			progressDialog.dismiss();
		}
		if(isFinishing())
		{
			if(completion != null)
			{
				completion.invoke(response);
			}
		}
	}
}
