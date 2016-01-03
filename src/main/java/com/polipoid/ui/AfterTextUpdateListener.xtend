package com.polipoid.ui

import android.text.TextWatcher
import android.text.Editable

/**
 * Little wrapper for the afterTextChanged event, to allow Xtend's lambda syntax
 * to be used.
 */
class AfterTextUpdateListener implements TextWatcher {
	private Runnable listener;

	new(Runnable listener) {
		this.listener = listener
	} 
	
	override afterTextChanged(Editable s) {
		listener.run()
	}
	
	override beforeTextChanged(CharSequence s, int start, int count, int after) {
		// Not interested in this event
	}
	
	override onTextChanged(CharSequence s, int start, int before, int count) {
		// Not interested in this event
	}
	
}