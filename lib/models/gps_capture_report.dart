import 'gps_metadata.dart';
import 'gps_state.dart';
import 'location_result.dart';

/// ===============================================================
/// GPS CAPTURE REPORT
/// ---------------------------------------------------------------
///
/// Resultado final de una captura GPS.
///
/// Contiene:
///
/// • Coordenada seleccionada
/// • Estado de la captura
/// • Score
/// • Estadísticas resumidas
/// • Metadata del dispositivo
///
/// Este objeto será utilizado por:
///
/// • ReportePage
/// • SQLite
/// • API
/// • Telemetría
///
/// ===============================================================

class GpsCaptureReport {

  //--------------------------------------------------------------
  // METADATA
  //--------------------------------------------------------------

  final GpsMetadata metadata;

  //--------------------------------------------------------------
  // ESTADO
  //--------------------------------------------------------------

  final GpsState state;

  //--------------------------------------------------------------
  // UBICACIÓN SELECCIONADA
  //--------------------------------------------------------------

  final LocationResult? location;

  //--------------------------------------------------------------
  // SCORE
  //--------------------------------------------------------------

  final double score;

  //--------------------------------------------------------------
  // CONFIANZA
  //--------------------------------------------------------------

  final double confidence;

  //--------------------------------------------------------------
  // SALUD DEL GPS
  //--------------------------------------------------------------

  final double health;

  //--------------------------------------------------------------
  // TIEMPO
  //--------------------------------------------------------------

  final Duration elapsed;

  //--------------------------------------------------------------
  // LECTURAS
  //--------------------------------------------------------------

  final int totalReadings;

  //--------------------------------------------------------------
  // VENTANA
  //--------------------------------------------------------------

  final int windowSize;

  //--------------------------------------------------------------
  // MÉTRICAS
  //--------------------------------------------------------------

  final double averageAccuracy;

  final double bestAccuracy;

  final double averageDistance;

  //--------------------------------------------------------------
  // FECHA
  //--------------------------------------------------------------

  final DateTime timestamp;

  //--------------------------------------------------------------
  // CONSTRUCTOR
  //--------------------------------------------------------------

  const GpsCaptureReport({

    required this.metadata,

    required this.state,

    required this.location,

    required this.score,

    required this.confidence,

    required this.health,

    required this.elapsed,

    required this.totalReadings,

    required this.windowSize,

    required this.averageAccuracy,

    required this.bestAccuracy,

    required this.averageDistance,

    required this.timestamp,

  });

  //--------------------------------------------------------------
  // COPY WITH
  //--------------------------------------------------------------

  GpsCaptureReport copyWith({

    GpsMetadata? metadata,

    GpsState? state,

    LocationResult? location,

    double? score,

    double? confidence,

    double? health,

    Duration? elapsed,

    int? totalReadings,

    int? windowSize,

    double? averageAccuracy,

    double? bestAccuracy,

    double? averageDistance,

    DateTime? timestamp,

  }) {

    return GpsCaptureReport(

      metadata: metadata ?? this.metadata,

      state: state ?? this.state,

      location: location ?? this.location,

      score: score ?? this.score,

      confidence: confidence ?? this.confidence,

      health: health ?? this.health,

      elapsed: elapsed ?? this.elapsed,

      totalReadings:
      totalReadings ?? this.totalReadings,

      windowSize:
      windowSize ?? this.windowSize,

      averageAccuracy:
      averageAccuracy ?? this.averageAccuracy,

      bestAccuracy:
      bestAccuracy ?? this.bestAccuracy,

      averageDistance:
      averageDistance ?? this.averageDistance,

      timestamp:
      timestamp ?? this.timestamp,

    );

  }

  //--------------------------------------------------------------
  // JSON
  //--------------------------------------------------------------

  Map<String, dynamic> toJson() {

    return {

      "metadata": metadata.toJson(),

      "state": state.name,

      "score": score,

      "confidence": confidence,

      "health": health,

      "elapsedMilliseconds":
      elapsed.inMilliseconds,

      "elapsedSeconds":
      elapsed.inSeconds,

      "totalReadings":
      totalReadings,

      "windowSize":
      windowSize,

      "averageAccuracy":
      averageAccuracy,

      "bestAccuracy":
      bestAccuracy,

      "averageDistance":
      averageDistance,

      "timestamp":
      timestamp.toIso8601String(),

      "location":
      location?.toJson(),

    };

  }

  //--------------------------------------------------------------
  // RESUMEN
  //--------------------------------------------------------------

  String summary() {

    return '''

==============================

GPS CAPTURE REPORT

==============================

Estado............. ${state.name}

Proveedor.......... ${metadata.provider}

Score.............. ${score.toStringAsFixed(1)}

Confianza.......... ${confidence.toStringAsFixed(1)} %

Salud.............. ${health.toStringAsFixed(1)} %

Tiempo............. ${elapsed.inSeconds} s

Lecturas........... $totalReadings

Ventana............ $windowSize

Accuracy Promedio.. ${averageAccuracy.toStringAsFixed(2)} m

Mejor Accuracy..... ${bestAccuracy.toStringAsFixed(2)} m

Centroide.......... ${averageDistance.toStringAsFixed(2)} m

Latitud............ ${location?.latitude}

Longitud........... ${location?.longitude}

Altitud............ ${location?.altitude}

Fuente............. ${location?.source.name}

Calidad............ ${location?.quality.name}

Satélites.......... ${location?.satellites}

Fecha.............. $timestamp

==============================

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