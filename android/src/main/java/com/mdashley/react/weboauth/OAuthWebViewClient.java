package com.mdashley.react.weboauth;

import android.net.Uri;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class OAuthWebViewClient extends WebViewClient
{
	private String scheme;
	private String host;
	private OAuthWebViewClientListener listener;

	public OAuthWebViewClient(String scheme, String host, OAuthWebViewClientListener listener)
	{
		this.scheme = scheme;
		this.host = host;
		this.listener = listener;
	}

	@Override
	public boolean shouldOverrideUrlLoading(WebView webView, String url)
	{
		Uri uri = Uri.parse(url);
		if(scheme.equals(uri.getScheme()) && host.equals(uri.getHost()))
		{
			this.listener.onIntendedURIReached(uri);
			return true;
		}
		return false;
	}
}
