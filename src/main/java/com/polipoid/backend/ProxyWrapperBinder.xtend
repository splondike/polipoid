package com.polipoid.backend

import android.os.Binder

/**
 * Binding returned by the backend service, no anonymous classes in Xtend as of writing.
 * 
 * @see No anonymous classes https://bugs.eclipse.org/bugs/show_bug.cgi?id=402388
 */
class ProxyWrapperBinder extends Binder {
	var ProxyWrapperService service = null

	new(ProxyWrapperService service) {
		this.service = service
	}

	def getService() {
		this.service
	}
}