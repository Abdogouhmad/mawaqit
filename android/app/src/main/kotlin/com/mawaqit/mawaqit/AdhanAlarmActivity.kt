package com.mawaqit.mawaqit

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Full-screen Adhan alarm shown over the lockscreen by [AdhanAlarmReceiver].
 *
 * `setShowWhenLocked(true)` + `setTurnScreenOn(true)` wake the display and
 * present the call without ever unlocking the device (PIN/biometric stay
 * protected). Volume/side keys and the on-screen Stop control all dismiss the
 * alarm through the single [AdhanScheduler.stopActive] path, so audio, the
 * foreground service, the tray card and this Activity are torn down together.
 */
class AdhanAlarmActivity : Activity() {

    private lateinit var clockView: TextView
    private lateinit var dateView: TextView
    private val mainHandler = Handler(Looper.getMainLooper())
    private val timeFormat = SimpleDateFormat("h:mm:ss a", Locale.getDefault())
    private val dateFormat = SimpleDateFormat("EEEE, MMMM d", Locale.getDefault())

    private val stopClock = object : Runnable {
        override fun run() {
            val now = Date()
            clockView.text = timeFormat.format(now)
            dateView.text = dateFormat.format(now)
            mainHandler.postDelayed(this, 1000L)
        }
    }

    private val stopBroadcast = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        setContentView(R.layout.activity_adhan_alarm)

        // The eyebrow above the title already says "ADHAN"; the title itself is
        // just the occurrence name ("Maghrib", "Test").
        val name = intent?.getStringExtra("name") ?: "Prayer"
        findViewById<TextView>(R.id.alarm_title).text = name
        clockView = findViewById(R.id.alarm_clock)
        dateView = findViewById(R.id.alarm_date)

        findViewById<Button>(R.id.alarm_stop).setOnClickListener { stopAdhan() }
        val filter = IntentFilter(AdhanScheduler.ACTION_STOP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopBroadcast, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopBroadcast, filter)
        }

        mainHandler.post(stopClock)
    }

    /** Volume/side keys dismiss the alarm instead of changing stream volume. */
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN &&
            (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)
        ) {
            stopAdhan()
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    /** Every dismissal route funnels through here. */
    fun stopAdhan() {
        AdhanScheduler.stopActive(this)
        finish()
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(stopClock)
        try {
            unregisterReceiver(stopBroadcast)
        } catch (_: Exception) {
            // Already unregistered — nothing to do.
        }
        super.onDestroy()
    }
}