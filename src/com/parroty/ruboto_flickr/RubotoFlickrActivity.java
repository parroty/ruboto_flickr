package com.parroty.ruboto_flickr;

import android.os.Bundle;

public class RubotoFlickrActivity extends org.ruboto.EntryPointActivity {
	public void onCreate(Bundle bundle) {
		getScriptInfo().setRubyClassName(getClass().getSimpleName());
	    super.onCreate(bundle);
	}
}
