package com.polipoid.backend

import android.app.PendingIntent
import android.app.Service
import android.content.ComponentCallbacks2
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.os.Build
import android.support.v4.app.NotificationCompat
import com.polipoid.R
import com.polipoid.ui.MainActivity

/**
 * Wraps the Polipo binary and provides an interface for interacting with it (start/stop, change configuration).
 */
class ProxyWrapperService extends Service {
	val private binder = new ProxyWrapperBinder(this)
	val private serviceRunningNotificationId = 1

	var private ProxyManager proxyManager = new ProxyManager(this)
	val private connectivityReceiver = new ConnectivityReceiver(this.proxyManager)
	val private polipoCrashReceiver = new PolipoCrashReceiver(this)
	

	def boolean isRunning() {
		this.proxyManager.isRunning
	}

	def void startProxy() {
		if (this.running) return;
		this.proxyManager.start()
		this.startForeground(this.serviceRunningNotificationId, buildNotification)
		this.registerReceiver(this.connectivityReceiver, 
			new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION)
		)
		this.registerReceiver(this.polipoCrashReceiver, 
			new IntentFilter("com.polipoid.polipo_crash")
		)
	}

	def void stopProxy() {
		if (!this.running) return;
		this.proxyManager.stop()
		this.stopForeground(true)
		this.unregisterReceiver(this.connectivityReceiver)
		this.unregisterReceiver(this.polipoCrashReceiver)
	}

	def private buildNotification() {
		// Intent to open the main UI
		val intent = PendingIntent.getActivity(this, 0, new Intent(this, MainActivity), 0)
		val res = this.getResources()

		// Make the notification icon show up against the tray background
		val tray_icon =
			if (Build.VERSION.SDK_INT > Build.VERSION_CODES.FROYO)
				R.drawable.tray_icon_light
			else 
				R.drawable.tray_icon_dark

		new NotificationCompat.Builder(this)
			.setContentTitle(res.getString(R.string.notification_title))
			.setContentText(res.getString(R.string.notification_message))
			.setSmallIcon(tray_icon)
			.setContentIntent(intent)
			.setOngoing(true)
			.setPriority(-1)
			.setWhen(0) // Hide the notification timestamp
			.build()
	}

	// Callbacks for the Android API

	def override onStartCommand(Intent intent, int flags, int startId) {
		switch intent?.action {
			case "start":
				this.startProxy()
		}

		return START_STICKY
	}

	def override onBind(Intent arg0) {
		this.binder
	}

	def override onUnbind(Intent intent) {
		if (!this.isRunning) {
			this.stopSelf()
		}

		false
	}

	def override onTrimMemory(int level) {
		// If I use only >= MODERATE, then I get things like MEMORY_UI_HIDDEN, which isn't what I want
		if (level >= ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE 
			&& level <= ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL) {
			this.proxyManager.reduceMemoryUsage()
		}
	}
}