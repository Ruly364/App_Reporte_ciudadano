import 'gps_state.dart';

/// ===============================================================
/// GPS DASHBOARD
/// ---------------------------------------------------------------
///
/// Estado actual del GPS Engine.
///
/// Esta clase está pensada para alimentar la interfaz gráfica
/// mientras se realiza la captura.
///
/// NO contiene lógica.
///
/// ===============================================================

class GpsDashboard {

  //--------------------------------------------------------------
  // ESTADO
  //--------------------------------------------------------------

  final GpsState state;

  //--------------------------------------------------------------
  // SCORE ACTUAL
  //--------------------------------------------------------------

  final double score;

  //--------------------------------------------------------------
  // ACCURACY
  //--------------------------------------------------------------

  /// Accuracy de la última lectura recibida.
  final double currentAccuracy;

  /// Mejor accuracy encontrado durante la captura.
  final double bestAccuracy;

  //--------------------------------------------------------------
  // INDICADORES
  //--------------------------------------------------------------

  /// Nivel de confianza (0-100)
  final double confidence;

  /// Salud del GPS (0-100)
  final double health;

  //--------------------------------------------------------------
  // LECTURAS
  //--------------------------------------------------------------

  final int readings;

  //--------------------------------------------------------------
  // SATÉLITES
  //--------------------------------------------------------------

  final int satellites;

  //--------------------------------------------------------------
  // TIEMPO
  //--------------------------------------------------------------

  final Duration elapsed;

  //--------------------------------------------------------------
  // PROVEEDOR GPS
  //--------------------------------------------------------------

  final String provider;

  //--------------------------------------------------------------
  // MENSAJE PARA LA INTERFAZ
  //--------------------------------------------------------------

  final String message;

  //--------------------------------------------------------------
  // ¿YA PUEDE FINALIZAR?
  //--------------------------------------------------------------

  final bool canFinish;

  //--------------------------------------------------------------
  // CONSTRUCTOR
  //--------------------------------------------------------------

  const GpsDashboard({

    required this.state,

    required this.score,

    required this.currentAccuracy,

    required this.bestAccuracy,

    required this.confidence,

    required this.health,

    required this.readings,

    required this.satellites,

    required this.elapsed,

    required this.provider,

    required this.message,

    required this.canFinish,

  });

  //--------------------------------------------------------------
  // JSON
  //--------------------------------------------------------------

  Map<String, dynamic> toJson() {

    return {

      "state": state.name,

      "score": score,

      "currentAccuracy": currentAccuracy,

      "bestAccuracy": bestAccuracy,

      "confidence": confidence,

      "health": health,

      "readings": readings,

      "satellites": satellites,

      "elapsedMilliseconds": elapsed.inMilliseconds,

      "elapsedSeconds": elapsed.inSeconds,

      "provider": provider,

      "message": message,

      "canFinish": canFinish,

    };

  }

  //--------------------------------------------------------------
  // COPY WITH
  //--------------------------------------------------------------

  GpsDashboard copyWith({

    GpsState? state,

    double? score,

    double? currentAccuracy,

    double? bestAccuracy,

    double? confidence,

    double? health,

    int? readings,

    int? satellites,

    Duration? elapsed,

    String? provider,

    String? message,

    bool? canFinish,

  }) {

    return GpsDashboard(

      state: state ?? this.state,

      score: score ?? this.score,

      currentAccuracy:
      currentAccuracy ?? this.currentAccuracy,

      bestAccuracy:
      bestAccuracy ?? this.bestAccuracy,

      confidence:
      confidence ?? this.confidence,

      health:
      health ?? this.health,

      readings:
      readings ?? this.readings,

      satellites:
      satellites ?? this.satellites,

      elapsed:
      elapsed ?? this.elapsed,

      provider:
      provider ?? this.provider,

      message:
      message ?? this.message,

      canFinish:
      canFinish ?? this.canFinish,

    );

  }

  //--------------------------------------------------------------
  // DEBUG
  //--------------------------------------------------------------

  @override
  String toString() {

    return '''

==============================

GPS DASHBOARD

==============================

Estado.............. ${state.name}

Score............... ${score.toStringAsFixed(1)}

Accuracy Actual..... ${currentAccuracy.toStringAsFixed(2)} m

Mejor Accuracy...... ${bestAccuracy.toStringAsFixed(2)} m

Confianza........... ${confidence.toStringAsFixed(1)} %

Salud............... ${health.toStringAsFixed(1)} %

Lecturas............ $readings

Satélites........... $satellites

Tiempo.............. ${elapsed.inSeconds} s

Proveedor........... $provider

Mensaje............. $message

Puede Finalizar..... $canFinish

==============================

''';

  }

}