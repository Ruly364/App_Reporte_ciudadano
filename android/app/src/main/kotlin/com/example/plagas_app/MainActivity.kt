package com.example.plagas_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val canal = "reportes_sincronizados"
    private val metodo = "plagas_app/notificaciones"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        crearCanal()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, metodo)
            .setMethodCallHandler { call, result ->
                if (call.method == "reporteEnviado") {
                    mostrarReporteEnviado(call.argument<String>("folio") ?: "Sin folio")
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun crearCanal() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                canal,
                "Reportes sincronizados",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Avisos cuando un reporte guardado sin conexión se envía."
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun mostrarReporteEnviado(folio: String) {
        val notification = NotificationCompat.Builder(this, canal)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Reporte enviado")
            .setContentText("Tu reporte $folio fue enviado correctamente.")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("Tu reporte $folio fue enviado correctamente."))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
    }
}
