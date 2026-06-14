package com.example.vivatpass

import android.content.Context
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object CrashHandler : Thread.UncaughtExceptionHandler {

    private const val FILE_NAME = "last_crash.txt"
    private var defaultHandler: Thread.UncaughtExceptionHandler? = null
    private var appContext: Context? = null

    fun init(context: Context) {
        appContext = context.applicationContext
        defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler(this)
    }

    override fun uncaughtException(thread: Thread, throwable: Throwable) {
        try {
            val sw = StringWriter()
            throwable.printStackTrace(PrintWriter(sw))
            val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
            val report = "=== CRASH REPORT ===\nTime: $timestamp\nThread: ${thread.name}\n\n$sw"

            appContext?.let { ctx ->
                File(ctx.filesDir, FILE_NAME).writeText(report)
            }
        } catch (_: Exception) {}

        defaultHandler?.uncaughtException(thread, throwable)
    }

    fun readAndClear(context: Context): String? {
        val file = File(context.filesDir, FILE_NAME)
        if (!file.exists()) return null
        val content = file.readText()
        file.delete()
        return content
    }
}
