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
import com.polipoid.backend.proxy.ProxyManager
import com.polipoid.ui.MainActivity
import java.io.InputStream
import com.polipoid.backend.proxy.UserConfigState
import com.polipoid.backend.proxy.StopReason
import android.net.wifi.WifiManager
import android.os.PowerManager
import android.content.Context

/**
 * Wraps the Polipo binary and provides an interface for interacting with it (start/stop, change configuration).
 */
class ProxyWrapperService extends Service {
	val private binder = new ProxyWrapperBinder(this)
	val private serviceRunningNotificationId = 1

	var private ProxyManager proxyManager = null
	var private ConnectivityReceiver connectivityReceiver = null
	var private PolipoCrashHandler polipoCrashReceiver = null
	var private WifiManager.WifiLock wifiLock = null
	var private PowerManager.WakeLock wakeLock = null

	def override void onCreate() {
		// These need to be instantiated here because ProxyManager makes use of Context in its constructor
		this.proxyManager = new ProxyManager(this)
		this.connectivityReceiver = new ConnectivityReceiver(this.proxyManager)
		this.polipoCrashReceiver = new PolipoCrashHandler(this)
		this.proxyManager.setStopListener[stopReason|
			if (StopReason.CRASH == stopReason) {
				this.startProxy()
				this.polipoCrashReceiver.handleCrash()
			}
		]
		val wifiManager = getSystemService(Context.WIFI_SERVICE) as WifiManager
		this.wifiLock = wifiManager.createWifiLock("proxy")
		val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
		this.wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "proxy")
	}

	def boolean isRunning() {
		this.proxyManager.proxyRunning
	}

	def void startProxy() {
		if (this.running) return;
		this.proxyManager.startProxy()
		this.startForeground(this.serviceRunningNotificationId, buildNotification)
		this.registerReceiver(this.connectivityReceiver, 
			new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION)
		)
		this.wifiLock.acquire()
		this.wakeLock.acquire()
	}

	def void stopProxy() {
		if (!this.running) return;
		this.proxyManager.stopProxy()
		this.stopForeground(true)
		this.unregisterReceiver(this.connectivityReceiver)
		this.wifiLock.release()
		this.wakeLock.release()
	}

	/**
	 * Verifies then installs the given stream as the user's preferred polipo configuration.
	 * Will close the InputStream once it's done.
	 *
	 * @throws IllegalArgumentException If the config isn't valid.
	 */
	def void installUserConfig(InputStream userConfStream) {
		this.proxyManager.installUserConfig(userConfStream)
		this.proxyManager.reloadSettings()
	}

	/**
	 * Enable or disable the users custom configuration
	 */
	def void enableUserConfig(boolean enableConfig) {
		this.proxyManager.enableUserConfig(enableConfig)
		this.proxyManager.reloadSettings()
	}

	/**
	 * Return whether the user has a custom configuration enabled
	 */
	def UserConfigState getUserConfigurationState() {
		this.proxyManager.userConfigurationState
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
			this.proxyManager.reduceProxyMemoryUsage()
		}
	}
}
