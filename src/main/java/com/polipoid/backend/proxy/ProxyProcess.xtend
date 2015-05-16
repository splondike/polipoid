package com.polipoid.backend.proxy

import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Responsible for managing an instance of the polipo binary.
 */
package class ProxyProcess {
	/**
	 * When sent to Polipo, causes it to dump its memory to disk and clear out its RAM cache
	 */
	val private static SIGNAL_DUMPMEM = 12

	/**
	 * Shuts down Polipo cleanly
	 */
	val private static SIGNAL_SHUTDOWN = 1

	var Process polipoProcess = null
	var Integer polipoPid = null
	/** 
	 * A Thread that restarts the polipo process if it crashes.
	 */
	var private Thread polipoMonitor = null

	/**
	 * If the user attaches a listener after polipo already stopped, we still want
	 * to fire it. Store the reason here.
	 */
	var private StopReason stopReason = null

	var private (StopReason)=>void stopListener = null

	package new(Process polipoProcess) {
		this.polipoProcess = polipoProcess

		// First line is the PID of the polipo process
	    val pidStr = new BufferedReader(new InputStreamReader(this.polipoProcess.inputStream)).readLine
	    this.polipoPid = Integer.parseInt(pidStr)
		this.polipoMonitor = new Thread[|
			try {
				this.waitForProcessToExit()
				// TODO: Check for port collision, send different failure message
				this.stopReason = StopReason.CRASH
				if (this.stopListener != null) this.stopListener.apply(this.stopReason)
			}
			catch (InterruptedException e) {
				// ProxyManager.stop() called, synchronization dealt with down there
			}
		]
		this.polipoMonitor.start()
	}

	def void stop() {
		if (!this.running) return;
		// Kill the monitor thread so we don't thing polipo's crashed
		this.polipoMonitor.interrupt()
		this.polipoMonitor = null

		// the killProcess call seems to not shut polipo down cleanly
		android.os.Process.sendSignal(this.polipoPid, ProxyProcess.SIGNAL_SHUTDOWN)
		this.waitForProcessToExit()

		// Only tell the listener we've stopped when the process is actually shut down
		this.stopReason = StopReason.STOPPED
		if (this.stopListener != null) this.stopListener.apply(this.stopReason)
	}

	def boolean isRunning() {
		this.polipoProcess != null
	}

	def void reduceMemoryUsage() {
		if (!this.running) return;
		android.os.Process.sendSignal(this.polipoPid, ProxyProcess.SIGNAL_DUMPMEM)
	}

	def void setStopListener((StopReason)=>void stopListener) {
		this.stopListener = stopListener	
		if (!this.running) {
			this.stopListener.apply(this.stopReason)
		}
	}

	/**
	 * Block the current thread until the polipo process exits
	 */
	def private int waitForProcessToExit() {
		if (!this.running) return -1;

		val returnCode = this.polipoProcess.waitFor
		this.polipoProcess = null
		this.polipoPid = null
		returnCode
	}
}