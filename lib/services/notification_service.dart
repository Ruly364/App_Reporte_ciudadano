import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ===============================================================
/// NOTIFICATION SERVICE
/// ===============================================================
///
/// Notificaciones locales de la aplicación.
///
/// Puede ejecutarse:
///
/// - con la aplicación abierta
/// - en segundo plano
/// - desde WorkManager
///
/// No depende de MainActivity ni de un MethodChannel.
/// ===============================================================

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  //==============================================================
  // CONFIGURACIÓN
  //==============================================================

  static const String _canalId =
      'reportes_enviados';

  static const String _canalNombre =
      'Reportes enviados';

  static const String _canalDescripcion =
      'Notificaciones cuando un reporte fue enviado correctamente.';

  //==============================================================
  // INICIALIZAR
  //==============================================================

  static Future<void> inicializar() async {
    if (_inicializado) {
      return;
    }

    if (!Platform.isAndroid) {
      _inicializado = true;
      return;
    }

    const androidSettings =
    AndroidInitializationSettings(
      'mipmap/ic_launcher',
    );

    const settings =
    InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: settings,
    );

    _inicializado = true;
  }

  //==============================================================
  // SOLICITAR PERMISO
  //==============================================================

  static Future<void> solicitarPermiso() async {
    if (!Platform.isAndroid) {
      return;
    }

    await inicializar();

    final android =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
  }

  //==============================================================
  // MOSTRAR REPORTE ENVIADO
  //==============================================================

  static Future<void> mostrarReporteEnviado(
      String? folio,
      ) async {
    if (!Platform.isAndroid) {
      return;
    }

    await inicializar();

    final android =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final habilitadas =
    await android?.areNotificationsEnabled();

    if (habilitadas == false) {
      return;
    }

    final numero =
    DateTime.now()
        .millisecondsSinceEpoch
        .remainder(2147483647);

    const detallesAndroid =
    AndroidNotificationDetails(
      _canalId,
      _canalNombre,
      channelDescription: _canalDescripcion,

      importance: Importance.max,
      priority: Priority.high,

      playSound: true,
      enableVibration: true,

      autoCancel: true,

      icon: 'mipmap/ic_launcher',
    );

    const detalles =
    NotificationDetails(
      android: detallesAndroid,
    );

    await _plugin.show(
      id: numero,
      title: 'Reporte enviado correctamente',
      body: folio != null && folio.isNotEmpty
          ? 'Folio: $folio'
          : 'El reporte fue enviado correctamente.',
      notificationDetails: detalles,
    );
  }
}