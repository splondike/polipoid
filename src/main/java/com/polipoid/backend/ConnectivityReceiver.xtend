package com.polipoid.backend

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.polipoid.backend.proxy.ProxyManager

class ConnectivityReceiver extends BroadcastReceiver {
	var ProxyManager proxyMan = null
	new(ProxyManager proxyManager) {
		this.proxyMan = proxyManager
	}
	override onReceive(Context context, Intent intent) {
		// Note that this method is called immediately when the receiver is registered
		this.proxyMan.updateOfflineMode()
	}
}