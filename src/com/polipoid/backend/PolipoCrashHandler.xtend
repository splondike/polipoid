package com.polipoid.backend

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.support.v4.app.NotificationCompat
import com.polipoid.R
import java.util.ArrayList
import java.util.Calendar
import java.util.Date
import java.util.List

/**
 * Monitors how often polipo is crashing, and shuts down the service with a notification if it's getting out of hand
 * TODO: This could disable the users configuration if it has been found to crash polipo.
 */
class PolipoCrashHandler {
	var ProxyWrapperService service = null
	val private serviceCrashedNotificationId = 936587432

	/**
	 * Maintains a log of the times polipo has crashed.
	 */
	var private List<Date> polipoCrashes = new ArrayList<Date>

	new(ProxyWrapperService service) {
		this.service = service
	}
	
	def handleCrash() {
		this.polipoCrashes.add(new Date)
		if (this.polipoCrashes.size > 4) {
			val earliestCrash = this.polipoCrashes.remove(0)
			val fiveMinutesAgoCal = Calendar.instance
			fiveMinutesAgoCal.add(Calendar.MINUTE, -5)
			if (earliestCrash.after(fiveMinutesAgoCal.time)) {
				this.showCrashNotification(this.service)
				this.service.stopProxy()
			}
		}
	}

	def private showCrashNotification(Context context) {
		val res = context.getResources()
		val url = res.getString(R.string.bug_report_url)
		val bugIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
		val pBugIntent = PendingIntent.getActivity(context, 0, bugIntent, PendingIntent.FLAG_ONE_SHOT)

		val iconBitmap = BitmapFactory.decodeResource(context.resources, R.drawable.polipo_crashed)
		val noti = new NotificationCompat.Builder(context)
			.setContentTitle(res.getString(R.string.polipo_crash_title))
			.setContentText(res.getString(R.string.polipo_crash_desc))
			.setSmallIcon(R.drawable.polipo_crashed)
			.setLargeIcon(iconBitmap)
			.setTicker(res.getString(R.string.polipo_crash_title))
			.setContentIntent(pBugIntent)
			.setAutoCancel(true)
			.build()
		context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager => [
			notify(this.serviceCrashedNotificationId, noti)
		]
	}
}