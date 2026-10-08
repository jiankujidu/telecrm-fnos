package com.telecrm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 悬浮窗拨号前台服务：在任意 App 上层显示当前拨打项，
 * 支持一键标记结果 / 拨打下一通，无需切回主程序（电销帮招牌功能）。
 */
class FloatDialerService : Service() {
    private var windowManager: WindowManager? = null
    private var floatView: View? = null
    private var channel: MethodChannel? = null

    private var currentPhone: String? = null
    private var currentName: String? = null
    private var currentCompany: String? = null
    private var currentTaskItemId: Int? = null
    private var currentCustomerId: Int? = null
    private var currentRedialLabel: String? = null

    companion object {
        private const val CHANNEL_ID = "telecrm_float"
        private const val NOTIF_ID = 9001
        var currentInstance: FloatDialerService? = null
    }

    override fun onCreate() {
        super.onCreate()
        currentInstance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val eng: FlutterEngine? = MainActivity.engine
        channel = eng?.dartExecutor?.binaryMessenger?.let { MethodChannel(it, "com.telecrm/float") }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForeground(NOTIF_ID, buildNotification())
        }
        // 来自 MainActivity 启动并携带当前项数据
        intent?.let {
            currentPhone = it.getStringExtra("phone")
            currentName = it.getStringExtra("name")
            currentCompany = it.getStringExtra("company")
            currentRedialLabel = it.getStringExtra("redialLabel")
            val ti = it.getIntExtra("taskItemId", -1)
            val ci = it.getIntExtra("customerId", -1)
            currentTaskItemId = if (ti < 0) null else ti
            currentCustomerId = if (ci < 0) null else ci
            if (it.getBooleanExtra("show", false)) showFloat()
        }
        return START_STICKY
    }

    private fun buildNotification(): Notification {
        val mgr = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(CHANNEL_ID, "电销悬浮拨号", NotificationManager.IMPORTANCE_LOW)
            mgr.createNotificationChannel(ch)
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("电销CRM 正在拨号")
            .setContentText("悬浮窗可一键标记与拨打下一通")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .build()
    }

    fun showFloat() {
        if (floatView != null) return
        if (!Settings.canDrawOverlays(this)) return
        val inflater = getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
        floatView = inflater.inflate(R.layout.float_dialer, null)
        bindData()

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        )
        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.x = 0
        params.y = 140

        floatView?.findViewById<View>(R.id.float_drag_handle)?.setOnTouchListener(object : View.OnTouchListener {
            var initialX = 0
            var initialY = 0
            var initialTouchX = 0f
            var initialTouchY = 0f

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                    }
                    MotionEvent.ACTION_MOVE -> {
                        params.x = initialX + (event.rawX - initialTouchX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager?.updateViewLayout(floatView, params)
                    }
                }
                return false
            }
        })

        floatView?.findViewById<View>(R.id.btn_empty)?.setOnClickListener { mark("empty") }
        floatView?.findViewById<View>(R.id.btn_not_answered)?.setOnClickListener { mark("not_answered") }
        floatView?.findViewById<View>(R.id.btn_connected)?.setOnClickListener { mark("connected") }
        floatView?.findViewById<View>(R.id.btn_add_customer)?.setOnClickListener { mark("add_customer") }
        floatView?.findViewById<View>(R.id.btn_next)?.setOnClickListener { next() }
        floatView?.findViewById<View>(R.id.btn_close)?.setOnClickListener { hideFloat() }
        floatView?.findViewById<View>(R.id.btn_close2)?.setOnClickListener { hideFloat() }

        windowManager?.addView(floatView, params)
    }

    private fun bindData() {
        floatView?.findViewById<TextView>(R.id.tv_company)?.text = currentCompany ?: ""
        floatView?.findViewById<TextView>(R.id.tv_name)?.text = currentName ?: "未知客户"
        floatView?.findViewById<TextView>(R.id.tv_phone)?.text = currentPhone ?: ""
        val rl = currentRedialLabel
        val tv = floatView?.findViewById<TextView>(R.id.tv_redial)
        if (rl.isNullOrBlank()) {
            tv?.visibility = View.GONE
        } else {
            tv?.visibility = View.VISIBLE
            tv?.text = rl
        }
    }

    fun updateCurrent(
        phone: String?,
        name: String?,
        company: String?,
        taskItemId: Int?,
        customerId: Int?,
        redialLabel: String?,
    ) {
        currentPhone = phone
        currentName = name
        currentCompany = company
        currentTaskItemId = taskItemId
        currentCustomerId = customerId
        currentRedialLabel = redialLabel
        if (floatView != null) bindData()
    }

    private fun mark(result: String) {
        channel?.invokeMethod(
            "onMark",
            mapOf(
                "phone" to (currentPhone ?: ""),
                "result" to result,
                "taskItemId" to (currentTaskItemId ?: -1),
                "customerId" to (currentCustomerId ?: -1),
            ),
        )
    }

    private fun next() {
        channel?.invokeMethod("onNext", null)
    }

    fun hideFloat() {
        if (floatView != null) {
            windowManager?.removeView(floatView)
            floatView = null
        }
    }

    override fun onDestroy() {
        hideFloat()
        currentInstance = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
