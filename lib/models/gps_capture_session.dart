import 'gps_capture_report.dart';
import 'gps_metadata.dart';
import 'gps_statistics.dart';
import 'location_result.dart';

/// ===============================================================
/// GPS CAPTURE SESSION
/// ---------------------------------------------------------------
///
/// Representa una sesión completa de captura GPS.
///
/// Incluye:
///
/// ✔ Metadata
/// ✔ Reporte final
/// ✔ Historial completo
/// ✔ Mejor ventana
/// ✔ Estadísticas
///
/// Esta clase puede:
///
/// • Guardarse en SQLite
/// • Enviarse a la API
/// • Exportarse a JSON
/// • Utilizarse para diagnóstico
///
/// ===============================================================

class GpsCaptureSession {

  //--------------------------------------------------------------
  // METADATA
  //--------------------------------------------------------------

  final GpsMetadata metadata;

  //--------------------------------------------------------------
  // REPORTE FINAL
  //--------------------------------------------------------------

  final GpsCaptureReport report;

  //--------------------------------------------------------------
  // HISTORIAL COMPLETO
  //--------------------------------------------------------------

  final List<LocationResult> history;

  //--------------------------------------------------------------
  // MEJOR VENTANA
  //--------------------------------------------------------------

  final List<LocationResult> bestWindow;

  //--------------------------------------------------------------
  // ESTADÍSTICAS
  //--------------------------------------------------------------

  final GpsStatistics statistics;

  //--------------------------------------------------------------
  // CONSTRUCTOR
  //--------------------------------------------------------------

  const GpsCaptureSession({

    required this.metadata,

    required this.report,

    required this.history,

    required this.bestWindow,

    required this.statistics,

  });

  //--------------------------------------------------------------
  // ¿LA SESIÓN ES VÁLIDA?
  //--------------------------------------------------------------

  bool get isValid {

    return report.location != null;

  }

  //--------------------------------------------------------------
  // TOTAL DE LECTURAS
  //--------------------------------------------------------------

  int get totalReadings {

    return history.length;

  }

  //--------------------------------------------------------------
  // ACCURACY FINAL
  //--------------------------------------------------------------

  double get finalAccuracy {

    return report.bestAccuracy;

  }

  //--------------------------------------------------------------
  // JSON
  //--------------------------------------------------------------

  Map<String, dynamic> toJson() {

    return {

      "metadata": metadata.toJson(),

      "report": report.toJson(),

      "history":

      history

          .map((e) => e.toJson())

          .toList(),

      "bestWindow":

      bestWindow

          .map((e) => e.toJson())

          .toList(),

      "statistics":

      statistics.toJson(),

    };

  }

  //--------------------------------------------------------------
  // COPY WITH
  //--------------------------------------------------------------

  GpsCaptureSession copyWith({

    GpsMetadata? metadata,

    GpsCaptureReport? report,

    List<LocationResult>? history,

    List<LocationResult>? bestWindow,

    GpsStatistics? statistics,

  }) {

    return GpsCaptureSession(

      metadata: metadata ?? this.metadata,

      report: report ?? this.report,

      history: history ?? this.history,

      bestWindow: bestWindow ?? this.bestWindow,

      statistics: statistics ?? this.statistics,

    );

  }

  //--------------------------------------------------------------
  // RESUMEN
  //--------------------------------------------------------------

  String summary() {

    return '''

=================================================

GPS CAPTURE SESSION

=================================================

Proveedor............ ${metadata.provider}

Dispositivo.......... ${metadata.device}

Fabricante........... ${metadata.manufacturer}

Modelo............... ${metadata.model}

Estado............... ${report.state.name}

Score................ ${report.score.toStringAsFixed(1)}

Confianza............ ${report.confidence.toStringAsFixed(1)} %

Salud................ ${report.health.toStringAsFixed(1)} %

Tiempo............... ${report.elapsed.inSeconds} s

Lecturas............. ${history.length}

Ventana.............. ${bestWindow.length}

Accuracy Promedio.... ${report.averageAccuracy.toStringAsFixed(2)} m

Mejor Accuracy....... ${report.bestAccuracy.toStringAsFixed(2)} m

Distancia Centroide.. ${report.averageDistance.toStringAsFixed(2)} m

Satélites............ ${metadata.satellites}

RTK.................. ${metadata.rtkFix}

=================================================

''';

  }

  //--------------------------------------------------------------
  // DEBUG
  //--------------------------------------------------------------

  @override
  String toString() {

    return summary();

  }

}