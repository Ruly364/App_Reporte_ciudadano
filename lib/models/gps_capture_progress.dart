import 'gps_dashboard.dart';
import 'location_result.dart';

/// ===============================================================
/// GPS CAPTURE PROGRESS
/// ---------------------------------------------------------------
///
/// Representa el progreso en tiempo real de una captura GPS.
///
/// Este objeto es utilizado por la interfaz (UI) para mostrar:
///
/// • Última lectura recibida
/// • Mejor lectura encontrada
/// • Estado actual del GPS
/// • Dashboard
///
/// No contiene lógica.
///
/// ===============================================================

class GpsCaptureProgress {

  //--------------------------------------------------------------
  // ÚLTIMA LECTURA
  //--------------------------------------------------------------

  final LocationResult? current;

  //--------------------------------------------------------------
  // MEJOR LECTURA
  //--------------------------------------------------------------

  final LocationResult? best;

  //--------------------------------------------------------------
  // DASHBOARD
  //--------------------------------------------------------------

  final GpsDashboard dashboard;

  //--------------------------------------------------------------
  // CONSTRUCTOR
  //--------------------------------------------------------------

  const GpsCaptureProgress({

    required this.current,

    required this.best,

    required this.dashboard,

  });

  //--------------------------------------------------------------
  // ¿EXISTE LECTURA?
  //--------------------------------------------------------------

  bool get hasCurrent {

    return current != null;

  }

  //--------------------------------------------------------------
  // ¿EXISTE MEJOR LECTURA?
  //--------------------------------------------------------------

  bool get hasBest {

    return best != null;

  }

  //--------------------------------------------------------------
  // ACCURACY ACTUAL
  //--------------------------------------------------------------

  double get currentAccuracy {

    return current?.accuracy ?? 0;

  }

  //--------------------------------------------------------------
  // MEJOR ACCURACY
  //--------------------------------------------------------------

  double get bestAccuracy {

    return best?.accuracy ?? 0;

  }

  //--------------------------------------------------------------
  // JSON
  //--------------------------------------------------------------

  Map<String, dynamic> toJson() {

    return {

      "current": current?.toJson(),

      "best": best?.toJson(),

      "dashboard": dashboard.toJson(),

    };

  }

  //--------------------------------------------------------------
  // COPY WITH
  //--------------------------------------------------------------

  GpsCaptureProgress copyWith({

    LocationResult? current,

    LocationResult? best,

    GpsDashboard? dashboard,

  }) {

    return GpsCaptureProgress(

      current: current ?? this.current,

      best: best ?? this.best,

      dashboard: dashboard ?? this.dashboard,

    );

  }

  //--------------------------------------------------------------
  // DEBUG
  //--------------------------------------------------------------

  @override
  String toString() {

    return '''

==============================

GPS CAPTURE PROGRESS

==============================

Current Accuracy.... ${current?.accuracy.toStringAsFixed(2) ?? "-"}

Best Accuracy....... ${best?.accuracy.toStringAsFixed(2) ?? "-"}

Latitude............ ${best?.latitude ?? "-"}

Longitude........... ${best?.longitude ?? "-"}

Score............... ${dashboard.score.toStringAsFixed(1)}

Confidence.......... ${dashboard.confidence.toStringAsFixed(1)}

Health.............. ${dashboard.health.toStringAsFixed(1)}

Readings............ ${dashboard.readings}

Elapsed............. ${dashboard.elapsed.inSeconds}s

State............... ${dashboard.state.name}

Provider............ ${dashboard.provider}

Message............. ${dashboard.message}

==============================

''';

  }

}