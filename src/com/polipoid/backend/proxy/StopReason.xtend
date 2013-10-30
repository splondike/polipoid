package com.polipoid.backend.proxy

enum StopReason {
	/**
	 * The process was stopped normally via {@link ProxyProcessManager.stop()}
	 */
	STOPPED,
	/**
	 * The underlying proxy process crashed
	 */
	CRASH
}