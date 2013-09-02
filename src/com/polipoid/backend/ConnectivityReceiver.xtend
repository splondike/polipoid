package com.polipoid.backend

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ConnectivityReceiver extends BroadcastReceiver {
	var ProxyManager proxyMan = null
	new(ProxyManager proxyManager) {
		this.proxyMan = proxyManager
	}
	override onReceive(Context context, Intent intent) {
		this.proxyMan.updateProxyOfflineSetting
	}
	
}