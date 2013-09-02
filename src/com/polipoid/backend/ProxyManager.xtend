package com.polipoid.backend

import android.content.Context
import android.net.ConnectivityManager
import com.google.common.base.Preconditions
import com.google.common.io.ByteStreams
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.FileReader
import java.io.FileWriter
import java.io.InputStreamReader

/**
 * Responsible for providing a running instance of the polipo binary.
 */
class ProxyManager {
	/**
	 * When sent to Polipo, causes it to dump its memory to disk and clear out its RAM cache
	 */
	val private static SIGNAL_DUMPMEM = 12

	/**
	 * Shuts down Polipo cleanly
	 */
	val private static SIGNAL_SHUTDOWN = 1

	var Context context = null
	/**
	 * Whether polipoProcess was started with proxyOffline=true or not
	 */
	var boolean polipoStartedOffline = false
	var Process polipoProcess = null
	var Integer polipoPid = null

	new(Context context) {
		this.context = context
	}
	/**
	 * Starts the polipo process
	 */
	def void start() {
		if (this.polipoProcess != null) return;

		checkInstallation()
		val userConf = new File(this.polipoDir, "user.conf")
		val defaultConf = new File(this.polipoDir, "default.conf")
		val conf = if (userConf.exists) userConf else defaultConf

		this.polipoProcess = this.startWithConf(conf)
		// First line is the PID of the polipo process
	    val pidStr = new BufferedReader(new InputStreamReader(this.polipoProcess.inputStream)).readLine
	    this.polipoPid = Integer.parseInt(pidStr)
		// TODO: Check for port collision
	}

	/**
	 * Starts the web server with the given config file.
	 * 
	 * We override some configurations which we always want to be the same (cache dir, log file etc.)
	 */
	def private Process startWithConf(File config) {
		Preconditions.checkArgument(config.exists, "Configuration file doesn't exist or can't be read.")
		val noSyslog = "logSyslog=false"
		val disableConfiguration = "disableLocalInterface=true"
		val disableWebServer = "localDocumentRoot="
		this.polipoStartedOffline = this.networkOffline
		val proxyOffline = "proxyOffline=" + this.polipoStartedOffline.toString
		val logFile = new File(this.context.cacheDir, "polipo.log").absolutePath
		val cachePath = new File(this.context.cacheDir, "polipo_cache").absolutePath

		val args = #["sh", "polipo-wrapper.sh", "-c", config.absolutePath, disableWebServer,
					 disableConfiguration, noSyslog, proxyOffline, "diskCacheRoot="+cachePath,
					 "logFile="+logFile]
		new ProcessBuilder(args)
			.directory(this.polipoDir) // So the wrapper script will know where the binary is
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

	def void stop() {
		if (this.polipoProcess == null) return;
		// the killProcess call seems to not shut polipo down cleanly
		android.os.Process.sendSignal(this.polipoPid, ProxyManager.SIGNAL_SHUTDOWN)
		this.polipoProcess.waitFor
		this.polipoProcess = null
		this.polipoPid = null
	}

	def boolean isRunning() {
		this.polipoProcess != null
	}

	def updateProxyOfflineSetting() {
		if (this.polipoStartedOffline != this.networkOffline) {
			this.stop()
			this.start()
		}
	}

	def void reduceMemoryUsage() {
		if (this.polipoProcess == null) return;
		android.os.Process.sendSignal(this.polipoPid, ProxyManager.SIGNAL_DUMPMEM)
	}

	/**
	 * Installs the polipo binary and default configuration file to where they can be
	 * used.
	 * 
	 * TODO: There may be some way to make the APK automatically write into lib/,
	 * JNI libraries seem to get it for free.
	 */
	def private checkInstallation() {
		if (this.installedVersion < this.currentVersion) {
			installBinary()
			installDefaultConfig()
			updateVersionFile()
		}
		installCacheDir()
	}

	def private installBinary() {
		val polipo = installFile("polipo")
		val polipoWrapper = installFile("polipo-wrapper.sh")
		new ProcessBuilder("chmod", "700", polipo.absolutePath).start().waitFor
		new ProcessBuilder("chmod", "700", polipoWrapper.absolutePath).start().waitFor
	}

	def private installDefaultConfig() {
		installFile("default.conf")
	}

	def private installCacheDir() {
		new File(this.context.cacheDir, "polipo_cache").mkdir
	}

	def private installFile(String name) {
		val outFile = new File(this.polipoDir, name)
		val asset = context.assets.open(name)
		val outStream = new FileOutputStream(outFile)
		ByteStreams.copy(asset, outStream)
		outStream.close()
		asset.close()
		outFile
	}

	def private updateVersionFile() {
		val versionFile = new File(this.polipoDir, "installed_version")
		val versionString = new Integer(this.currentVersion).toString
		// Files.write from Guava doesn't work in android 2.2
		val fw = new FileWriter(versionFile)
		fw.write(versionString)
		fw.close()
	}

	def private getInstalledVersion() {
		val versionFile = new File(this.polipoDir, "installed_version")
		if (versionFile.exists) {
			// Files.toString from Guava doesn't work in android 2.2
			val versionStr = new BufferedReader(new FileReader(versionFile)).readLine()
			try {
				Integer.parseInt(versionStr)
			}
			catch (NumberFormatException e) {
				0
			}
		}
		else {
			0
		}
	}	

	def private getCurrentVersion() {
		this.context.packageManager.getPackageInfo(this.context.packageName, 0).versionCode
	}

	def private getPolipoDir() {
		context.getDir("polipo", Context.MODE_PRIVATE)
	}
}