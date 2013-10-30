package com.polipoid.ui

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.CheckBox
import android.widget.TextView
import com.polipoid.R
import java.io.FileNotFoundException
import java.io.InputStream
import android.widget.Toast
import com.polipoid.backend.proxy.UserConfigState

class SettingsActivity extends Activity {
	static val SELECT_CONF_RESULT_ID = 1

	val backendConnection = new ProxyWrapperConnection(this)

	def override void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_settings)
	}

	def override void onResume() {
		super.onResume()
		// Put this onResume in case the user installs first file manager after opening Polipo
        updateView()
	}

	def override void onDestroy() {
		super.onDestroy()
		this.backendConnection.close()
	}

	def void selectConf(View view) {
		this.startActivityForResult(this.selectIntent, SettingsActivity.SELECT_CONF_RESULT_ID);
	}

	def void toggleUserConfig(View view) {
		this.backendConnection.withService[service|
			val toggleConfButton = this.findViewById(R.id.enableUserConfig) as CheckBox
			service.enableUserConfig(toggleConfButton.checked)
			this.updateView()
		]
	}

	def override void onActivityResult(int requestCode, int resultCode, Intent data) {
		if (requestCode == SettingsActivity.SELECT_CONF_RESULT_ID) {
			if (data == null) return;
			try {
				val confStream = this.contentResolver.openInputStream(data.data)
				this.installUserConfig(confStream)
				this.updateView()
			}
			catch (FileNotFoundException e) {
				val errorMsg = this.resources.getString(R.string.conf_stream_invalid)
				this.showErrorMessage(errorMsg)
			}
		}
	}

	def private void installUserConfig(InputStream userConfStream) {
		this.backendConnection.withService[service|
			try {
				service.installUserConfig(userConfStream)
				val toastText = this.resources.getString(R.string.user_config_updated)
				Toast.makeText(this, toastText, Toast.LENGTH_SHORT).show()
			}
			catch (IllegalArgumentException e) {
				this.showErrorMessage(e.message);
			}
		]
	}

	def private void showErrorMessage(String msg) {
		new AlertDialog.Builder(this)
			.setMessage(msg)
			.show()
	}

	def private Intent selectIntent() {
		val selectIntent = new Intent(Intent.ACTION_GET_CONTENT);
		selectIntent.type = "text/*";
		selectIntent.addCategory(Intent.CATEGORY_DEFAULT) // TODO: Not sure this is necessary ...
		selectIntent
	}

	def private void updateView() {
		// Normalize the checkbox state 
		val toggleConfButton = this.findViewById(R.id.enableUserConfig) as CheckBox
		toggleConfButton.setEnabled(true)
		toggleConfButton.setChecked(false)

		// Warning: The toggling of the enable user config button by these two methods
		// is a little finicky due to the async service call
        setCustomConfToggleStatus()
        handleActivityAvailability()
	}

	def private void setCustomConfToggleStatus() {
		this.backendConnection.withService[service|
			val toggleConfButton = this.findViewById(R.id.enableUserConfig) as CheckBox
			val confState = service.userConfigurationState
			switch(confState) {
				case UserConfigState.NONE: toggleConfButton.setEnabled(false)
				case UserConfigState.DISABLED: toggleConfButton.setChecked(false)
				case UserConfigState.ENABLED: toggleConfButton.setChecked(true)
			}
		]
	}

	/**
	 * The users system may not have an activity capable of selecting text files.
	 * This toggles the visibility/enabledness of UI components appropriately.
	 */
	def private void handleActivityAvailability() {
		val noSelectHandler = this.packageManager.queryIntentActivities(this.selectIntent, 0).empty
		val needFileSelectorText = this.findViewById(R.id.noFileSelector) as TextView
		val selectConfButton = this.findViewById(R.id.uploadConfButton) as Button
		val toggleConfButton = this.findViewById(R.id.enableUserConfig) as CheckBox

		if (noSelectHandler) {
			needFileSelectorText.setVisibility(View.VISIBLE)
			selectConfButton.setEnabled(false)
			toggleConfButton.setEnabled(false)
		} else {
			needFileSelectorText.setVisibility(View.GONE)
			selectConfButton.setEnabled(true)
		}
	}
}