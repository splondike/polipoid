package com.polipoid.backend.proxy

import android.content.Context
import com.google.common.io.ByteStreams
import com.google.common.io.Files
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.FileReader
import java.io.FileWriter
import java.io.InputStream
import java.io.InputStreamReader
import java.util.LinkedList
import java.util.List

/**
 * Manages the filesystem associated with the proxy.
 */
package class Installation {
	/**
	 * The maximum size in bytes we'll accept for a configuration file.
	 * Polipo can't handle config files > 50kb, and locks up, hence this sanity check.
	 */
	val private static MAX_CONFIG_SIZE = 20480

	var Context context = null

	private new(Context context) {
		this.context = context
	}


	/**
	 * Entry method to get an Installation instance
	 */
	def static Installation setup(Context context) {
		val rtn = new Installation(context)
		rtn.checkInstallation()
		rtn
	}

	/**
	 * Enable or disable the users custom configuration
	 */
	def void enableUserConfig(boolean enableConfig) {
		if (enableConfig && this.disabledUserConfig.exists) {
			if (this.userConfig.exists) {
				// This shouldn't happen, but this would be the sensible thing to do
				this.disabledUserConfig.delete()
			}
			else {
				Files.move(this.disabledUserConfig, this.userConfig)
			}
		}
		else if (!enableConfig && this.userConfig.exists) {
			Files.move(this.userConfig, this.disabledUserConfig)
		}
		else {
			// We don't have the files, or they already match the boolean
		}
	}

	/**
	 * Return whether the user has a custom configuration enabled
	 */
	def UserConfigState getUserConfigurationState() {
		if (this.userConfig.exists) {
			UserConfigState.ENABLED
		}
		else if (this.disabledUserConfig.exists) {
			UserConfigState.DISABLED
		}
		else {
			UserConfigState.NONE
		}
	}

	/**
	 * Verifies then installs the given stream as the user's preferred polipo configuration.
	 * Will close the InputStream once it's done.
	 *
	 * @throws IllegalArgumentException If the config isn't valid, or looks too large (in bytes)
	 */
	def installUserConfig(InputStream userConfStream) {
		/*
		 * An InputStream seemed better than a File or a String:
		 *  - String: If user tried to upload a huge binary by accident this freezes the app
		 *  - File: Rather unclean with cleaning up after itself, I either move the file (distateful mutation),
		 *    or copy it, making the caller clean up.
	     */
	    val tempConfFile = this.configToTempFile(userConfStream, MAX_CONFIG_SIZE)

		val configErrors = configErrors(tempConfFile)
		if (configErrors.empty) {
			Files.copy(tempConfFile, this.userConfig)
		}
		else {
			// TODO: Not sure this is the right exception type..
			throw new IllegalArgumentException("Error on line " + configErrors.head)
		}
	}

	def private List<String> configErrors(File config) {
		checkInstallation()
		// -v works at the moment to make polipo exit while printing the config errors.
		// this will need to be checked on binary upgrades.
		val args = #[this.polipoWrapper.absolutePath, this.polipoBinary.absolutePath, "-c", config.absolutePath, "-v"]
		val process = new ProcessBuilder(args)
			.directory(this.polipoDir) // So the wrapper script will know where the binary is
			.start()

		process.waitFor()

		val errors = new LinkedList<String>();
	    val inputReader = new BufferedReader(new InputStreamReader(process.errorStream))
	    while(inputReader.ready) {
	    	val line = inputReader.readLine
	    	if (line.startsWith(config.absolutePath)) {
	    		errors.push(line.replace(config.absolutePath + ":", ""))
	    	}
	    }

		return errors
	}

	def private File configToTempFile(InputStream fileStream, Integer maxSize) {
		val tempConfFile = File.createTempFile("polipo", "conf")
		val os = new FileOutputStream(tempConfFile);
 
		var totalRead = 0;
		var read = 0;
		// This is a somewhat inefficient way of doing it compared to a multiple byte buffer
		// but Xtend doesn't support instantiating sized arrays
 		while ((read = fileStream.read()) != -1) {
 			os.write(read)
 			totalRead = totalRead + 1
 			if (totalRead > maxSize) {
 				fileStream.close()
 				tempConfFile.delete()
 				// TODO: Translate me
 				throw new IllegalArgumentException("Config file too big (max size is " + maxSize + " bytes)")
 			}
 		}
 		fileStream.close()
 		os.close()
		tempConfFile
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
		val polipo = installFile(this.polipoBinary.name)
		val polipoWrapper = installFile(this.polipoWrapper.name)
		new ProcessBuilder("chmod", "700", polipo.absolutePath).start().waitFor
		new ProcessBuilder("chmod", "700", polipoWrapper.absolutePath).start().waitFor
	}

	def private installDefaultConfig() {
		installFile(this.defaultConfig.name)
	}

	def private installCacheDir() {
		this.cacheDir.mkdir
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

	def File getConfigFile() {
		if (this.userConfig.exists) this.userConfig else this.defaultConfig
	}

	def getUserConfig() {
		new File(this.polipoDir, "user.conf")
	}

	def getDisabledUserConfig() {
		new File(this.polipoDir, "user.conf.disabled")
	}

	def getDefaultConfig() {
		new File(this.polipoDir, "default.conf")
	}

	def getPolipoBinary() {
		new File(this.polipoDir, "polipo")
	}

	def getPolipoWrapper() {
		new File(this.polipoDir, "polipo-wrapper.sh")
	}

	def getCacheDir() {
		new File(this.context.cacheDir, "polipo_cache")
	}

	def getLogFile() {
		new File(this.context.cacheDir, "polipo.log")
	}

	def getPolipoDir() {
		context.getDir("polipo", Context.MODE_PRIVATE)
	}
}