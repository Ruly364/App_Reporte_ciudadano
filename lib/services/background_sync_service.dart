import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notification_service.dart';
import 'offline_service.dart';
import 'sync_service.dart';

/// ===============================================================
/// BACKGROUND SYNC SERVICE
/// ===============================================================
///
/// Punto de entrada de Android WorkManager.
///
/// Este código puede ejecutarse aunque la aplicación no tenga
/// abierta la interfaz.
/// ===============================================================

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
        (task, inputData) async {
      try {
        //========================================================
        // REGISTRAR PLUGINS EN EL ISOLATE DE BACKGROUND
        //========================================================

        DartPluginRegistrant.ensureInitialized();

        debugPrint(
          'BackgroundSync: tarea iniciada: $task',
        );

        //========================================================
        // INICIALIZAR NOTIFICACIONES
        //========================================================

        await NotificationService.inicializar();

        //========================================================
        // SINCRONIZAR
        //========================================================

        final enviados =
        await SyncService.sincronizarPendientes();

        debugPrint(
          'BackgroundSync: '
              '$enviados reporte(s) enviado(s).',
        );

        //========================================================
        // COMPROBAR SI TODAVÍA QUEDAN PENDIENTES
        //========================================================

        final pendientes =
        await OfflineService.pendientes();

        debugPrint(
          'BackgroundSync: '
              '$pendientes pendiente(s) restantes.',
        );

        //========================================================
        // RESULTADO PARA WORKMANAGER
        //========================================================
        //
        // true:
        //   trabajo terminado.
        //
        // false:
        //   Android debe volver a intentarlo.
        //
        //========================================================

        if (pendientes == 0) {
          return true;
        }

        return false;
      } catch (e, stack) {
        debugPrint(
          'BackgroundSync: error: $e',
        );

        debugPrintStack(
          stackTrace: stack,
        );

        // Pedimos a WorkManager que vuelva a intentar.
        return false;
      }
    },
  );
}

/// ===============================================================
/// CONTROLADOR
/// ===============================================================

class BackgroundSyncService {
  BackgroundSyncService._();

  static bool _inicializado = false;

  static Future<void> inicializar() async {
    if (_inicializado) {
      return;
    }

    await Workmanager().initialize(
      callbackDispatcher,
    );

    _inicializado = true;

    debugPrint(
      'BackgroundSyncService inicializado.',
    );
  }
}