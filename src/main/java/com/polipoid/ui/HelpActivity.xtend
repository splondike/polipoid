package com.polipoid.ui

import android.app.Activity
import android.os.Bundle
import com.polipoid.R
import android.view.View
import android.content.Intent
import android.net.Uri

class HelpActivity extends Activity {
	def override onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_help)
	}

	def flattrClicked(View view) {
		val url = this.resources.getString(R.string.flattr_url)
		val urlIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
		this.startActivity(urlIntent);
	}
}