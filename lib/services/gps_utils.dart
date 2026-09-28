import '../models/location_quality.dart';

/// ===============================================================
/// GPS UTILS
/// ---------------------------------------------------------------
/// Funciones auxiliares para el GPS Engine.
/// ===============================================================

class GpsUtils {

  GpsUtils._();

  //---------------------------------------------------------
  // Calidad según accuracy
  //---------------------------------------------------------

  static LocationQuality quality(double accuracy) {

    if (accuracy <= 3) {
      return LocationQuality.excellent;
    }

    if (accuracy <= 5) {
      return LocationQuality.veryGood;
    }

    if (accuracy <= 10) {
      return LocationQuality.good;
    }

    if (accuracy <= 20) {
      return LocationQuality.fair;
    }

    return LocationQuality.poor;

  }

  //---------------------------------------------------------
  // ¿Accuracy aceptable?
  //---------------------------------------------------------

  static bool isAcceptable({

    required double accuracy,

    required double target,

  }) {

    return accuracy <= target;

  }

  //---------------------------------------------------------
  // ¿Accuracy válido?
  //---------------------------------------------------------

  static bool isValid(double accuracy) {

    return accuracy > 0 &&
        accuracy < 100;

  }

  //---------------------------------------------------------
  // Distancia entre dos Accuracy
  //---------------------------------------------------------

  static double difference(

      double current,

      double previous,

      ) {

    return (current - previous).abs();

  }

}