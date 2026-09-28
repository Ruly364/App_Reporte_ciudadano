import 'location_quality.dart';
import 'location_source.dart';

/// ===============================================================
/// GPS STATISTICS
/// ---------------------------------------------------------------
/// Estadísticas de una sesión GPS.
///
/// Esta clase únicamente recopila información.
/// No calcula el Score.
///
/// ===============================================================

class GpsStatistics {

  //--------------------------------------------------------------
  // TIEMPOS
  //--------------------------------------------------------------

  DateTime? startTime;

  DateTime? endTime;

  //--------------------------------------------------------------
  // LECTURAS
  //--------------------------------------------------------------

  int totalReadings = 0;

  //--------------------------------------------------------------
  // ACCURACY
  //--------------------------------------------------------------

  double? firstAccuracy;

  double? lastAccuracy;

  double? bestAccuracy;

  double? worstAccuracy;

  double _accuracySum = 0;

  //--------------------------------------------------------------
  // VELOCIDAD
  //--------------------------------------------------------------

  double _speedSum = 0;

  //--------------------------------------------------------------
  // SATÉLITES
  //--------------------------------------------------------------

  int bestSatellites = 0;

  //--------------------------------------------------------------
  // FUENTE
  //--------------------------------------------------------------

  LocationSource source = LocationSource.androidGps;

  //--------------------------------------------------------------
  // CALIDAD
  //--------------------------------------------------------------

  LocationQuality quality = LocationQuality.poor;

  //--------------------------------------------------------------
  // CONSTRUCTOR
  //--------------------------------------------------------------

  GpsStatistics();

  //--------------------------------------------------------------
  // INICIAR
  //--------------------------------------------------------------

  void start() {

    startTime = DateTime.now();

    endTime = null;

    totalReadings = 0;

    firstAccuracy = null;

    lastAccuracy = null;

    bestAccuracy = null;

    worstAccuracy = null;

    _accuracySum = 0;

    _speedSum = 0;

    bestSatellites = 0;

  }

  //--------------------------------------------------------------
  // FINALIZAR
  //--------------------------------------------------------------

  void finish() {

    endTime = DateTime.now();

  }

  //--------------------------------------------------------------
  // AGREGAR LECTURA
  //--------------------------------------------------------------

  void addReading({

    required double accuracy,

    required double speed,

    required int satellites,

    required LocationSource source,

    required LocationQuality quality,

  }) {

    totalReadings++;

    firstAccuracy ??= accuracy;

    lastAccuracy = accuracy;

    _accuracySum += accuracy;

    _speedSum += speed;

    if (bestAccuracy == null ||
        accuracy < bestAccuracy!) {

      bestAccuracy = accuracy;

    }

    if (worstAccuracy == null ||
        accuracy > worstAccuracy!) {

      worstAccuracy = accuracy;

    }

    if (satellites > bestSatellites) {

      bestSatellites = satellites;

    }

    this.source = source;

    this.quality = quality;

  }

  //--------------------------------------------------------------
  // DURACIÓN
  //--------------------------------------------------------------

  Duration get duration {

    if (startTime == null) {

      return Duration.zero;

    }

    return (endTime ?? DateTime.now())
        .difference(startTime!);

  }

  //--------------------------------------------------------------
  // ACCURACY PROMEDIO
  //--------------------------------------------------------------

  double get averageAccuracy {

    if (totalReadings == 0) {

      return 0;

    }

    return _accuracySum / totalReadings;

  }

  //--------------------------------------------------------------
  // VELOCIDAD PROMEDIO
  //--------------------------------------------------------------

  double get averageSpeed {

    if (totalReadings == 0) {

      return 0;

    }

    return _speedSum / totalReadings;

  }

  //--------------------------------------------------------------
  // MEJORA DE ACCURACY
  //--------------------------------------------------------------

  double get improvement {

    if (firstAccuracy == null ||
        bestAccuracy == null) {

      return 0;

    }

    return firstAccuracy! - bestAccuracy!;

  }

  //--------------------------------------------------------------
  // JSON
  //--------------------------------------------------------------

  Map<String, dynamic> toJson() {

    return {

      "startTime": startTime?.toIso8601String(),

      "endTime": endTime?.toIso8601String(),

      "durationMilliseconds":
      duration.inMilliseconds,

      "durationSeconds":
      duration.inSeconds,

      "totalReadings":
      totalReadings,

      "firstAccuracy":
      firstAccuracy,

      "lastAccuracy":
      lastAccuracy,

      "bestAccuracy":
      bestAccuracy,

      "worstAccuracy":
      worstAccuracy,

      "averageAccuracy":
      averageAccuracy,

      "averageSpeed":
      averageSpeed,

      "improvement":
      improvement,

      "bestSatellites":
      bestSatellites,

      "source":
      source.name,

      "quality":
      quality.name,

    };

  }

  //--------------------------------------------------------------
  // COPY WITH
  //--------------------------------------------------------------

  GpsStatistics copy() {

    final copy = GpsStatistics();

    copy.startTime = startTime;

    copy.endTime = endTime;

    copy.totalReadings = totalReadings;

    copy.firstAccuracy = firstAccuracy;

    copy.lastAccuracy = lastAccuracy;

    copy.bestAccuracy = bestAccuracy;

    copy.worstAccuracy = worstAccuracy;

    copy._accuracySum = _accuracySum;

    copy._speedSum = _speedSum;

    copy.bestSatellites = bestSatellites;

    copy.source = source;

    copy.quality = quality;

    return copy;

  }

  //--------------------------------------------------------------
  // DEBUG
  //--------------------------------------------------------------

  @override
  String toString() {

    return '''

==============================

GPS STATISTICS

==============================

Duration............ ${duration.inSeconds}s

Readings............ $totalReadings

First Accuracy...... ${firstAccuracy?.toStringAsFixed(2)}

Last Accuracy....... ${lastAccuracy?.toStringAsFixed(2)}

Best Accuracy....... ${bestAccuracy?.toStringAsFixed(2)}

Worst Accuracy...... ${worstAccuracy?.toStringAsFixed(2)}

Average Accuracy.... ${averageAccuracy.toStringAsFixed(2)}

Average Speed....... ${averageSpeed.toStringAsFixed(2)}

Improvement......... ${improvement.toStringAsFixed(2)}

Satellites.......... $bestSatellites

Source.............. ${source.name}

Quality............. ${quality.name}

==============================

''';

  }

}