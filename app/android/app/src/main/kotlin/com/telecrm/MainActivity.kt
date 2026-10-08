package com.telecrm

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.CallLog
import android.provider.Settings
import android.telecom.TelecomManager
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val DIALER_CHANNEL = "com.telecrm/dialer"
    private val REC_CHANNEL = "com.telecrm/recording"
    private val FLOAT_CHANNEL = "com.telecrm/float"
    private var recordingChannel: MethodChannel? = null
    private var callStateListener: PhoneStateListener? = null
    private var lastState = TelephonyManager.CALL_STATE_IDLE

    companion object {
        /** 缓存的 FlutterEngine，供前台悬浮窗服务复用同一消息通道 */
        var engine: FlutterEngine? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MainActivity.engine = flutterEngine

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIALER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "call" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        val simSlot = call.argument<Int>("simSlot") ?: -1
                        result.success(placeCall(phone, simSlot))
                    }
                    "readCallLogs" -> result.success(readCallLogs())
                    "scanRecordings" -> result.success(scanRecordings())
                    else -> result.notImplemented()
                }
            }

        recordingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, REC_CHANNEL)
        recordingChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableCallMonitor" -> {
                    registerCallStateListener()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        registerCallStateListener()

        registerFloatChannel(flutterEngine)
    }

    /** 悬浮窗通道：接收 Dart 的 start/show/hide/stop 控制命令 */
    private fun registerFloatChannel(fe: FlutterEngine) {
        MethodChannel(fe.dartExecutor.binaryMessenger, FLOAT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    startFloatService()
                    result.success(null)
                }
                "show" -> {
                    showFloatWindow(call.arguments as? Map<*, *>)
                    result.success(null)
                }
                "hide" -> {
                    FloatDialerService.currentInstance?.hideFloat()
                    result.success(null)
                }
                "stop" -> {
                    FloatDialerService.currentInstance?.stopSelf()
                    result.success(null)
                }
                "openOverlaySettings" -> {
                    openOverlaySettings()
                    result.success(null)
                }
                "canDrawOverlay" -> result.success(Settings.canDrawOverlays(this))
                else -> result.notImplemented()
            }
        }
    }

    /** 启动前台悬浮窗服务（无权限则引导设置页） */
    private fun startFloatService() {
        if (!Settings.canDrawOverlays(this)) {
            openOverlaySettings()
            return
        }
        if (FloatDialerService.currentInstance == null) {
            val intent = Intent(this, FloatDialerService::class.java)
            ContextCompat.startForegroundService(this, intent)
        }
    }

    /** 显示/更新悬浮窗并填充当前拨打项 */
    private fun showFloatWindow(d: Map<*, *>?) {
        if (!Settings.canDrawOverlays(this)) {
            openOverlaySettings()
            return
        }
        val phone = d?.get("phone") as? String ?: ""
        val name = d?.get("name") as? String
        val company = d?.get("company") as? String
        val redialLabel = d?.get("redialLabel") as? String
        val taskItemId = (d?.get("taskItemId") as? Int) ?: -1
        val customerId = (d?.get("customerId") as? Int) ?: -1
        val svc = FloatDialerService.currentInstance
        if (svc == null) {
            val intent = Intent(this, FloatDialerService::class.java).apply {
                putExtra("show", true)
                putExtra("phone", phone)
                putExtra("name", name)
                putExtra("company", company)
                putExtra("redialLabel", redialLabel)
                putExtra("taskItemId", taskItemId)
                putExtra("customerId", customerId)
            }
            ContextCompat.startForegroundService(this, intent)
        } else {
            svc.updateCurrent(
                phone = phone,
                name = name,
                company = company,
                taskItemId = if (taskItemId < 0) null else taskItemId,
                customerId = if (customerId < 0) null else customerId,
                redialLabel = redialLabel,
            )
            svc.showFloat()
        }
    }

    /** 跳转系统设置开启“显示悬浮窗”权限 */
    private fun openOverlaySettings() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:$packageName"),
        )
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    /** 通话状态监听：挂断后通知 Dart 自动回传最近录音（监听仅创建一次，可重复注册） */
    private fun registerCallStateListener() {
        val tm = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager ?: return
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return // 未授权则不监听，自动上传功能静默关闭
        }
        if (callStateListener == null) {
            callStateListener = object : PhoneStateListener() {
                @Suppress("DEPRECATION")
                override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                    if (state == TelephonyManager.CALL_STATE_IDLE && lastState != TelephonyManager.CALL_STATE_IDLE) {
                        // 通话刚结束：把最近外拨号码回传 Dart
                        recordingChannel?.invokeMethod("onCallEnded", mapOf("phone" to (lastOutgoingNumber() ?: "")))
                    }
                    lastState = state
                }
            }
        }
        val listener = callStateListener
        if (listener != null) {
            try {
                @Suppress("DEPRECATION")
                tm.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
            } catch (_: Exception) {
                // 监听注册失败不影响其它功能
            }
        }
    }

    /** 读取最近一条外拨号码（用于关联录音到对应通话记录） */
    private fun lastOutgoingNumber(): String? {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG)
            != PackageManager.PERMISSION_GRANTED
        ) return null
        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            arrayOf(CallLog.Calls.NUMBER),
            "${CallLog.Calls.TYPE} = ?",
            arrayOf(CallLog.Calls.OUTGOING_TYPE.toString()),
            "${CallLog.Calls.DATE} DESC LIMIT 1",
        )
        cursor?.use {
            if (it.moveToFirst()) return it.getString(0)
        }
        return null
    }

    /** 扫描通话录音文件（各厂商路径不同，返回按修改时间倒序的路径列表） */
    @Suppress("DEPRECATION")
    private fun scanRecordings(): List<String> {
        val candidates = mutableListOf<File>()
        val dirs = mutableListOf<File>()

        // 应用专属录音目录（无需额外权限）
        getExternalFilesDir(Environment.DIRECTORY_RECORDINGS)?.let { dirs.add(it) }
        // 公共录音目录
        try {
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_RECORDINGS)
                ?.let { dirs.add(it) }
        } catch (_: Exception) {
        }
        // 常见厂商录音路径
        val root = Environment.getExternalStorageDirectory()
        listOf(
            "CallRecorder", "Sound Record", "Recordings", "Call Recordings",
            "MIUI/sound_recorder", "Record", "Voice Recorder", "Sounds",
        ).forEach { dirs.add(File(root, it)) }

        val exts = setOf("mp3", "m4a", "amr", "3gp", "wav", "ogg", "aac")
        val cutoff = System.currentTimeMillis() - TimeUnit.MINUTES.toMillis(15)

        for (d in dirs) {
            d.listFiles()?.forEach { f ->
                if (f.isFile && exts.contains(f.extension.lowercase()) && f.lastModified() >= cutoff) {
                    candidates.add(f)
                }
            }
            d.listFiles { f: File -> f.isDirectory }?.forEach { sub ->
                sub.listFiles()?.forEach { f ->
                    if (f.isFile && exts.contains(f.extension.lowercase()) && f.lastModified() >= cutoff) {
                        candidates.add(f)
                    }
                }
            }
        }
        candidates.sortByDescending { it.lastModified() }
        return candidates.map { it.absolutePath }
    }

    /**
     * 使用指定 SIM 卡直拨（Android 5.1+ 支持双卡）。
     * 有 CALL_PHONE 权限 -> ACTION_CALL 直接拨出；
     * 没权限 -> 降级 ACTION_DIAL 唤起系统拨号界面（不需要权限），保证用户点了一定有反应。
     */
    private fun placeCall(phone: String, simSlot: Int): Map<String, Any> {
        if (phone.isBlank()) return mapOf("ok" to false, "message" to "号码为空")
        val uri = Uri.parse("tel:${Uri.encode(phone)}")
        val granted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.CALL_PHONE
        ) == PackageManager.PERMISSION_GRANTED

        return try {
            if (granted) {
                val intent = Intent(Intent.ACTION_CALL, uri)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && simSlot >= 0) {
                    val telecom = getSystemService(TELECOM_SERVICE) as TelecomManager
                    val accounts = telecom.callCapablePhoneAccounts
                    if (accounts.size > simSlot) {
                        intent.putExtra("android.telecom.extra.PHONE_ACCOUNT_HANDLE", accounts[simSlot])
                    }
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                mapOf("ok" to true, "message" to "", "needPermission" to false)
            } else {
                // 降级：只唤起拨号界面，用户手动点一下即可拨出
                val intent = Intent(Intent.ACTION_DIAL, uri)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                mapOf(
                    "ok" to true,
                    "message" to "已唤起拨号界面，授予「电话」权限后可自动直拨",
                    "needPermission" to true,
                )
            }
        } catch (e: SecurityException) {
            try {
                val intent = Intent(Intent.ACTION_DIAL, uri)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                mapOf(
                    "ok" to true,
                    "message" to "已唤起拨号界面，授予「电话」权限后可自动直拨",
                    "needPermission" to true,
                )
            } catch (e2: Exception) {
                mapOf("ok" to false, "message" to "拨号失败：${e2.message}", "needPermission" to true)
            }
        } catch (e: Exception) {
            mapOf("ok" to false, "message" to "拨号失败：${e.message}")
        }
    }

    /** 读取系统通话记录 */
    @Suppress("DEPRECATION")
    private fun readCallLogs(): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.DURATION, CallLog.Calls.DATE),
            null,
            null,
            "${CallLog.Calls.DATE} DESC LIMIT 50",
        )
        cursor?.use {
            while (it.moveToNext()) {
                list.add(
                    mapOf(
                        "number" to (it.getString(0) ?: ""),
                        "duration" to (it.getInt(1) ?: 0),
                        "date" to (it.getLong(2) ?: 0L),
                    ),
                )
            }
        }
        return list
    }
}
