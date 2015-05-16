package com.polipoid.backend.proxy

import android.content.Context
import android.net.ConnectivityManager
import java.io.InputStream

/**
 * Responsible for managing the polipo file system, and an associated process.
 */
class ProxyManager {
	var Context context = null

	var Installation installation = null

	/**
	 * Whether {@link this.process} is running in offline mode.
	 */
	var boolean inOfflineMode = false
	var ProxyProcess process = null

	var (StopReason) => void stopListener = null

	new(Context context) {
		this.context = context
		this.installation = Installation.setup(context)
	}

	def void startProxy() {
		if (!this.proxyRunning) {
			this.inOfflineMode = this.networkOffline
			this.process = new ProxyProcess(this.startPolipo(this.inOfflineMode))
			this.process.setStopListener[stopReason|
				if (this.stopListener != null) {
					this.stopListener.apply(stopReason)
				}
			]
		}
	}

	def void stopProxy() {
		if (this.proxyRunning) {
			this.process.stop()
		}
	}

	def void reloadSettings() {
		if (this.proxyRunning) {
			this.stopProxy()
			this.startProxy()
		}
	}

	/**
	 * Align the running process with the current network connectivity state.
	 */
	def void updateOfflineMode() {
		if (this.proxyRunning && this.networkOffline != this.inOfflineMode) {
			this.stopProxy()
			this.startProxy()
		}
	}

	def boolean isProxyRunning() {
		this.process != null && this.process.running
	}

	def void reduceProxyMemoryUsage() {
		if (this.proxyRunning) {
			this.process.reduceMemoryUsage()
		}
	}

	def void installUserConfig(InputStream stream) {
		this.installation.installUserConfig(stream)
	}

	/**
	 * Enable or disable the users custom configuration
	 */
	def void enableUserConfig(boolean enableConfig) {
		this.installation.enableUserConfig(enableConfig)
	}

	/**
	 * Return whether the user has a custom configuration enabled
	 */
	def UserConfigState getUserConfigurationState() {
		this.installation.userConfigurationState
	}

	/**
	 * 
	 */
	def void setStopListener((StopReason)=>void stopListener) {
		this.stopListener = stopListener
	}

	/**
	 * Starts the polipo binary.
	 * We override some configurations which we always want to be the same (cache dir, log file etc.)
	 * 
	 * @param offlineMode Whether to start Polipo in offline mode
	 */
	def private Process startPolipo(boolean offlineMode) {
		val polipoWrapper = this.installation.polipoWrapper.absolutePath
		val polipoBinary = this.installation.polipoBinary.absolutePath
		val configFile = this.installation.configFile.absolutePath
		val logFile = this.installation.logFile.absolutePath
		val cacheDir = this.installation.cacheDir.absolutePath

		val noSyslog = "logSyslog=false"
		val disableConfiguration = "disableLocalInterface=true"
		val disableWebServer = "localDocumentRoot="
		val proxyOffline = "proxyOffline=" + offlineMode.toString

		val args = #[polipoWrapper, polipoBinary, "-c", configFile, disableWebServer,
					 disableConfiguration, noSyslog, proxyOffline, "diskCacheRoot="+cacheDir,
					 "logFile="+logFile]
		new ProcessBuilder(args)
			.start()
	}

	def private Boolean isNetworkOffline() {
		val connMan = this.context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
		val netInfo = connMan.activeNetworkInfo
		if (netInfo != null) {
			!netInfo.connected
		}
		else {
			true
		}
	}
}