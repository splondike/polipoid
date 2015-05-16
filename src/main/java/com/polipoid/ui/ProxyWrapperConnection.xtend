package com.polipoid.ui

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import com.polipoid.backend.ProxyWrapperBinder
import com.polipoid.backend.ProxyWrapperService
import java.util.LinkedList

/**
 * Connects to the backend service, responsible for communicating with the backend.
 */
class ProxyWrapperConnection implements ServiceConnection {
	var Context context = null
	var ProxyWrapperService service = null
	var connectingToService = false
	/**
	 * Stores a scheduled queue of functions to be run once a connection to the
	 * service has been established. Probably important that they are ordered.
	 */
	var runQueue = new LinkedList<(ProxyWrapperService) => void>

	new(Context context) {
		this.context = context
	}

	def override onServiceConnected(ComponentName name, IBinder service) {
		this.service = (service as ProxyWrapperBinder).service
		this.connectingToService = false

		for (func : this.runQueue) {
			func.apply(this.service)
		}
		this.runQueue.clear()
	}
	
	def override onServiceDisconnected(ComponentName name) {
		this.service = null
	}

	def close() {
		if (this.service != null) {
			this.context.unbindService(this)
		}
	}

	/**
	 * Schedules the given function to be run when the service is successfully bound
	 */
	def void withService((ProxyWrapperService) => void func) {
		if (this.service != null) {
			func.apply(this.service)
		}
		else {
			this.bindToService()
			this.runQueue.add(func)
		}
	}

	/**
	 * Used by BootCompletedReceiver to start the service, normal clients should use the direct object
	 * reference via the 'withService' call.
	 */
	def void startProxy() {
		val intent = new Intent(this.context, ProxyWrapperService)
		intent.setAction("start")
		this.context.startService(intent)
	}

	def private void bindToService() {
		if (this.connectingToService) return;

		this.connectingToService = true
		val intent = new Intent(this.context, ProxyWrapperService)
		// Required to call startService to make the service sticky
		this.context.startService(intent)
		val bound = this.context.bindService(intent, this, Context.BIND_AUTO_CREATE)
		if (!bound) throw new IllegalStateException("Could not bind to ProxyWrapperService")
	}
}