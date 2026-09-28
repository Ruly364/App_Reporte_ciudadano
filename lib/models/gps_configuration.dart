/// ===============================================================
/// GPS CONFIGURATION
/// ---------------------------------------------------------------
/// Configuración del motor GPS.
///
/// Cada perfil (Rápido, Alta Precisión, Bosque, GNSS Externo)
/// utiliza una instancia de esta clase para definir el
/// comportamiento del algoritmo.
///
/// No contiene lógica de negocio.
/// Sólo parámetros de configuración.
///
/// ===============================================================

class GpsConfiguration {

  //==============================================================
  // PRECISIÓN
  //==============================================================

  /// Precisión objetivo en metros.
  final double targetAccuracy;

  /// Número de lecturas consecutivas que deben cumplir
  /// la precisión objetivo antes de iniciar el refinamiento.
  final int stableReadings;

  /// Número de lecturas utilizadas para calcular
  /// la mejor ventana.
  final int scoringWindowSize;

  //==============================================================
  // TIEMPOS
  //==============================================================

  /// Tiempo adicional que continuará refinando la captura
  /// una vez alcanzada la precisión objetivo.
  final Duration refinementTime;

  /// Tiempo máximo permitido para una captura.
  final Duration timeout;

  //==============================================================
  // PESOS DEL ALGORITMO
  //==============================================================

  /// Peso de Accuracy.
  final double accuracyWeight;

  /// Peso de Estabilidad.
  final double stabilityWeight;

  /// Peso de Consistencia Espacial.
  final double consistencyWeight;

  /// Peso del Tiempo de Captura.
  final double timeWeight;

  //==============================================================
  // FUTURO (GNSS EXTERNO)
  //==============================================================

  /// Cantidad mínima de satélites requerida.
  final int minimumSatellites;

  /// HDOP máximo aceptable.
  final double? maximumHdop;

  /// Permitir utilizar proveedor externo.
  final bool allowExternalGnss;

  /// Permitir utilizar GPS interno.
  final bool allowInternalGps;

  const GpsConfiguration({

    required this.targetAccuracy,

    required this.stableReadings,

    required this.scoringWindowSize,

    required this.refinementTime,

    required this.timeout,

    this.accuracyWeight = 0.40,

    this.stabilityWeight = 0.25,

    this.consistencyWeight = 0.20,

    this.timeWeight = 0.15,

    this.minimumSatellites = 0,

    this.maximumHdop,

    this.allowExternalGnss = true,

    this.allowInternalGps = true,

  });

  //==============================================================
  // VALIDACIÓN
  //==============================================================

  bool get isValid {

    final total =

        accuracyWeight +
            stabilityWeight +
            consistencyWeight +
            timeWeight;

    return (total - 1.0).abs() < 0.001;

  }

  //==============================================================
  // COPIAR CONFIGURACIÓN
  //==============================================================

  GpsConfiguration copyWith({

    double? targetAccuracy,

    int? stableReadings,

    int? scoringWindowSize,

    Duration? refinementTime,

    Duration? timeout,

    double? accuracyWeight,

    double? stabilityWeight,

    double? consistencyWeight,

    double? timeWeight,

    int? minimumSatellites,

    double? maximumHdop,

    bool? allowExternalGnss,

    bool? allowInternalGps,

  }) {

    return GpsConfiguration(

      targetAccuracy:
      targetAccuracy ?? this.targetAccuracy,

      stableReadings:
      stableReadings ?? this.stableReadings,

      scoringWindowSize:
      scoringWindowSize ?? this.scoringWindowSize,

      refinementTime:
      refinementTime ?? this.refinementTime,

      timeout:
      timeout ?? this.timeout,

      accuracyWeight:
      accuracyWeight ?? this.accuracyWeight,

      stabilityWeight:
      stabilityWeight ?? this.stabilityWeight,

      consistencyWeight:
      consistencyWeight ?? this.consistencyWeight,

      timeWeight:
      timeWeight ?? this.timeWeight,

      minimumSatellites:
      minimumSatellites ?? this.minimumSatellites,

      maximumHdop:
      maximumHdop ?? this.maximumHdop,

      allowExternalGnss:
      allowExternalGnss ?? this.allowExternalGnss,

      allowInternalGps:
      allowInternalGps ?? this.allowInternalGps,

    );

  }

  //==============================================================
  // JSON
  //==============================================================

  Map<String, dynamic> toJson() {

    return {

      "targetAccuracy": targetAccuracy,

      "stableReadings": stableReadings,

      "scoringWindowSize": scoringWindowSize,

      "refinementTime": refinementTime.inMilliseconds,

      "timeout": timeout.inMilliseconds,

      "accuracyWeight": accuracyWeight,

      "stabilityWeight": stabilityWeight,

      "consistencyWeight": consistencyWeight,

      "timeWeight": timeWeight,

      "minimumSatellites": minimumSatellites,

      "maximumHdop": maximumHdop,

      "allowExternalGnss": allowExternalGnss,

      "allowInternalGps": allowInternalGps,

    };

  }

  factory GpsConfiguration.fromJson(
      Map<String, dynamic> json) {

    return GpsConfiguration(

      targetAccuracy:
      (json["targetAccuracy"] as num).toDouble(),

      stableReadings:
      json["stableReadings"],

      scoringWindowSize:
      json["scoringWindowSize"],

      refinementTime:
      Duration(
        milliseconds:
        json["refinementTime"],
      ),

      timeout:
      Duration(
        milliseconds:
        json["timeout"],
      ),

      accuracyWeight:
      (json["accuracyWeight"] as num?)?.toDouble() ?? 0.40,

      stabilityWeight:
      (json["stabilityWeight"] as num?)?.toDouble() ?? 0.25,

      consistencyWeight:
      (json["consistencyWeight"] as num?)?.toDouble() ?? 0.20,

      timeWeight:
      (json["timeWeight"] as num?)?.toDouble() ?? 0.15,

      minimumSatellites:
      json["minimumSatellites"] ?? 0,

      maximumHdop:
      (json["maximumHdop"] as num?)?.toDouble(),

      allowExternalGnss:
      json["allowExternalGnss"] ?? true,

      allowInternalGps:
      json["allowInternalGps"] ?? true,

    );

  }

  //==============================================================
  // DEBUG
  //==============================================================

  @override
  String toString() {

    return '''
===============================
GPS CONFIGURATION
===============================

Target Accuracy : ${targetAccuracy.toStringAsFixed(2)} m

Stable Readings : $stableReadings

Window Size     : $scoringWindowSize

Refinement      : ${refinementTime.inSeconds} s

Timeout         : ${timeout.inSeconds} s

Accuracy Weight : ${(accuracyWeight * 100).toStringAsFixed(0)}%

Stability Weight: ${(stabilityWeight * 100).toStringAsFixed(0)}%

Consistency     : ${(consistencyWeight * 100).toStringAsFixed(0)}%

Time Weight     : ${(timeWeight * 100).toStringAsFixed(0)}%

Minimum Sats    : $minimumSatellites

HDOP Max        : ${maximumHdop ?? "-"}
''';

  }

}