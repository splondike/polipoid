package com.polipoid.ui

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.EditText
import android.widget.Toast
import com.polipoid.R
import com.polipoid.backend.ProxyWrapperService
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream
import java.io.InputStreamReader
import java.nio.CharBuffer
import java.nio.charset.Charset

class SettingsActivity extends Activity {
	val backendConnection = new ProxyWrapperConnection(this)
	var boolean saveItemEnabled
	var Menu menu
	
	static String SAVE_STATE_KEY = "SAVE_STATE_KEY"

	def override void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_settings)

        if (savedInstanceState == null) {
        	this.reloadContent()
        } else {
			if (savedInstanceState.containsKey(SettingsActivity.SAVE_STATE_KEY)) {
				this.saveItemEnabled = savedInstanceState.getBoolean(SettingsActivity.SAVE_STATE_KEY)
			} else {
				this.saveItemEnabled = false
			}
        }
	}

	def override void onDestroy() {
		super.onDestroy()
		this.backendConnection.close()
	}
	
    def override onCreateOptionsMenu(Menu menu) {
    	super.onCreateOptionsMenu(menu)
        menuInflater.inflate(R.menu.settings, menu)
        this.menu = menu
        this.addChangeListener(menu)
        return true
    }

	def override onPrepareOptionsMenu(Menu menu) {
		super.onPrepareOptionsMenu(menu)
        this.restoreSaveItemState(menu)
		return true
	}

    def private restoreSaveItemState(Menu menu) {
    	val saveItem = menu.findItem(R.id.update_settings)
    	saveItem.enabled = this.saveItemEnabled
    }

	def private addChangeListener(Menu menu) {
		val textBox = findViewById(R.id.txt_settings) as EditText
		textBox.addTextChangedListener(new AfterTextUpdateListener[|
			val saveItem = menu.findItem(R.id.update_settings)
			saveItem.enabled = true
			this.saveItemEnabled = true
		])
	}

	def override boolean onOptionsItemSelected(MenuItem view) {
		switch view.itemId {
			case R.id.update_settings: {
				this.updateSettings()
				true
			}
			case R.id.reset_settings: {
				this.resetConfig()
				true
			}
			case R.id.open_manual: {
				val url = "http://www.pps.univ-paris-diderot.fr/~jch/software/polipo/polipo.html#Variable-index"
				val i = new Intent(Intent.ACTION_VIEW)
				i.setData(Uri.parse(url))
				this.startActivity(i)
				true
			}
			default:
				false
		}
	}

	def override onSaveInstanceState(Bundle bundle) {
		super.onSaveInstanceState(bundle)
		bundle.putBoolean(SettingsActivity.SAVE_STATE_KEY, this.saveItemEnabled)
	}

	def void updateSettings() {
		val textBox = findViewById(R.id.txt_settings) as EditText
		val textLen = textBox.text.length
		val charArray = newCharArrayOfSize(textLen)
		textBox.text.getChars(0, textLen, charArray, 0)
		val byteBuffer = Charset.forName("UTF-8").encode(CharBuffer.wrap(charArray))
		val contentStream = new ByteArrayInputStream(byteBuffer.array)
		try {
			this.installUserConfig(contentStream)
			this.reloadContent()
		} catch (IllegalArgumentException e) {
			this.showErrorMessage(e.message);
		}
	}

	def void resetConfig() {
		this.backendConnection.withService[service|
			service.resetToDefaultConfig()
			this.reloadContent()
			val toastText = this.resources.getString(R.string.config_reset)
			Toast.makeText(this, toastText, Toast.LENGTH_SHORT).show()
		]
	}

	def private void installUserConfig(InputStream userConfStream) {
		this.backendConnection.withService[service|
			service.installUserConfig(userConfStream)
			val toastText = this.resources.getString(R.string.user_config_updated)
			Toast.makeText(this, toastText, Toast.LENGTH_SHORT).show()
		]
	}

	def private reloadContent() {
		val textBox = findViewById(R.id.txt_settings) as EditText
		this.backendConnection.withService[service|
			val conf = this.getConfig(service)
			textBox.setText(conf)
		]
		if (this.menu != null) {
			val saveItem = this.menu.findItem(R.id.update_settings)
			saveItem.enabled = false
			this.saveItemEnabled = false
		}
	}

	def private getConfig(ProxyWrapperService service) {
		try {
			val conf = service.getConfig()
			inputStreamToCharSequence(conf)
		} catch (IOException e) {
			service.resetToDefaultConfig()
			val conf = service.getConfig()
			inputStreamToCharSequence(conf)
		}
	}

	def private static CharSequence inputStreamToCharSequence(InputStream is) {
	    val char[] buffer = newCharArrayOfSize(1)
	    val StringBuilder out = new StringBuilder();
		val input = new InputStreamReader(is, "UTF-8")
		var rsz = 0
	    while((rsz = input.read(buffer, 0, buffer.length)) >= 0) {
	        out.append(buffer, 0, rsz);
	    }
	    return out;
	}

	def private void showErrorMessage(String msg) {
		new AlertDialog.Builder(this)
			.setMessage(msg)
			.show()
	}
}