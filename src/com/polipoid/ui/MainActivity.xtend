package com.polipoid.ui

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.preference.PreferenceManager
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Button
import android.widget.CheckBox
import com.polipoid.R

class MainActivity extends Activity {
	val backendConnection = new ProxyWrapperConnection(this)

    def override onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setProxyToggleStatus()
        setBasicConfigStatus()
    }

	def override onDestroy() {
		super.onDestroy()
		this.backendConnection.close()
	}

    def override onCreateOptionsMenu(Menu menu) {
        menuInflater.inflate(R.menu.main, menu)
        return true
    }

	def private setProxyToggleStatus() {
		val toggleButton = findViewById(R.id.btn_toggle_proxy) as Button
		this.backendConnection.withService[service|
			toggleButton.text = if (service.running) R.string.stop_proxy else R.string.start_proxy
			toggleButton.enabled = true
		]
	}

	def private setBasicConfigStatus() {
		val prefs = PreferenceManager.getDefaultSharedPreferences(this)
		val chkAutostart = findViewById(R.id.chk_autostart) as CheckBox
		chkAutostart.checked = prefs.getBoolean("autostart", false)
	}

	// UI Callbacks

	def toggleProxy(View view) {
		this.backendConnection.withService[service|
			if (service.running)
				service.stopProxy()
			else
				service.startProxy()
			this.setProxyToggleStatus()
		]
	}

	def toggleAutostart(View view) {
		val prefs = PreferenceManager.getDefaultSharedPreferences(this).edit
		prefs.putBoolean("autostart", (view as CheckBox).checked)
		prefs.commit
		false
	}

	/**
	 * Handle the activity menu.
	 * 
	 * Needed because android 2.2 doesn't support the XML onclick version.
	 */
	def override boolean onOptionsItemSelected(MenuItem view) {
		switch view.itemId {
			case R.id.action_help: {
				this.startActivity(new Intent(this, HelpActivity))
				true
			}
			case R.id.action_settings: {
				this.startActivity(new Intent(this, SettingsActivity))
				true
			}
			default:
				false
		}
	}
}