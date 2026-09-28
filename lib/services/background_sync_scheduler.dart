import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundSyncScheduler {
  BackgroundSyncScheduler._();

  static const String taskName =
      'plagas_sync_pendientes';

  static const String uniqueName =
      'plagas_sync_pendientes_unico';

  //==============================================================
  // PROGRAMAR
  //==============================================================

  static Future<void> programar() async {
    try {
      await Workmanager().registerOneOffTask(
        uniqueName,
        taskName,

        initialDelay:
        const Duration(seconds: 5),

        constraints:
        Constraints(
          networkType:
          NetworkType.connected,
        ),

        existingWorkPolicy:
        ExistingWorkPolicy.keep,

        backoffPolicy:
        BackoffPolicy.exponential,

        backoffPolicyDelay:
        const Duration(minutes: 1),
      );

      debugPrint(
        'BackgroundSyncScheduler: '
            'sincronización programada.',
      );
    } catch (e) {
      debugPrint(
        'BackgroundSyncScheduler: '
            'no se pudo programar: $e',
      );
    }
  }
}