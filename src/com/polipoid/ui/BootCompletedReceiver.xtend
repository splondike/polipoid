package com.polipoid.ui

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.preference.PreferenceManager

/**
 * Listens for the android.intent.action.BOOT_COMPLETED intent and starts the proxy if the user
 * wants it.
 * 
 * @see http://stackoverflow.com/questions/1056570/how-to-autostart-an-android-application
 * for how it is called.
 */
class BootCompletedReceiver extends BroadcastReceiver {
	override onReceive(Context context, Intent intent) {
		val prefs = PreferenceManager.getDefaultSharedPreferences(context)
		if (prefs.getBoolean("autostart", false)) {
			val conn = new ProxyWrapperConnection(context)
			conn.startProxy()
		}
	}
}