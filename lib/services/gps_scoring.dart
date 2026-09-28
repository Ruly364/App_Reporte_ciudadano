import '../models/gps_configuration.dart';
import '../models/location_result.dart';

/// ===============================================================
/// GPS SCORING
/// ---------------------------------------------------------------
///
/// Calcula un Score (0-100) para una ventana GPS.
///
/// El Score considera:
///
/// ✔ Accuracy
/// ✔ Estabilidad
/// ✔ Consistencia espacial
/// ✔ Tiempo de captura
///
/// Esta clase NO conoce Flutter.
/// NO conoce Android.
/// NO conoce Garmin.
///
/// ===============================================================

class GpsScoring {

  GpsScoring._();

  //--------------------------------------------------------------
  // SCORE TOTAL
  //--------------------------------------------------------------

  static double calculate({

    required List<LocationResult> history,

    required Duration elapsed,

    required GpsConfiguration configuration,

  }) {

    if (history.isEmpty) {

      return 0;

    }

    final accuracyScore =
    _accuracy(history);

    final stabilityScore =
    _stability(history);

    final consistencyScore =
    _consistency(history);

    final timeScore =
    _time(

      elapsed,

      configuration.timeout,

    );

    final total =

        accuracyScore *
            configuration.accuracyWeight +

            stabilityScore *
                configuration.stabilityWeight +

            consistencyScore *
                configuration.consistencyWeight +

            timeScore *
                configuration.timeWeight;

    return total.clamp(0, 100);

  }

  //--------------------------------------------------------------
  // ACCURACY
  //--------------------------------------------------------------

  static double _accuracy(

      List<LocationResult> history) {

    final avg =

        history

            .map((e) => e.accuracy)

            .reduce((a, b) => a + b)

            /

            history.length;

    if (avg <= 1) return 100;

    if (avg <= 2) return 98;

    if (avg <= 3) return 96;

    if (avg <= 5) return 92;

    if (avg <= 7) return 85;

    if (avg <= 10) return 75;

    if (avg <= 15) return 60;

    if (avg <= 20) return 45;

    return 20;

  }

  //--------------------------------------------------------------
  // ESTABILIDAD
  //--------------------------------------------------------------

  static double _stability(

      List<LocationResult> history) {

    if (history.length < 2) {

      return 100;

    }

    double variation = 0;

    for (int i = 1;

    i < history.length;

    i++) {

      variation +=

          (history[i].accuracy -

              history[i - 1].accuracy)

              .abs();

    }

    variation /=

    (history.length - 1);

    if (variation <= 0.20) return 100;

    if (variation <= 0.50) return 95;

    if (variation <= 1) return 90;

    if (variation <= 2) return 80;

    if (variation <= 3) return 65;

    if (variation <= 5) return 45;

    return 20;

  }

  //--------------------------------------------------------------
  // CONSISTENCIA ESPACIAL
  //--------------------------------------------------------------

  static double _consistency(

      List<LocationResult> history) {

    if (history.length < 2) {

      return 100;

    }

    double lat = 0;

    double lon = 0;

    for (final p in history) {

      lat += p.latitude;

      lon += p.longitude;

    }

    lat /= history.length;

    lon /= history.length;

    double dispersion = 0;

    for (final p in history) {

      final d =

          ((p.latitude - lat).abs() +

              (p.longitude - lon).abs()) *

              111000;

      dispersion += d;

    }

    dispersion /= history.length;

    if (dispersion <= 1) return 100;

    if (dispersion <= 2) return 95;

    if (dispersion <= 3) return 90;

    if (dispersion <= 5) return 82;

    if (dispersion <= 8) return 70;

    if (dispersion <= 12) return 55;

    return 35;

  }

  //--------------------------------------------------------------
  // TIEMPO
  //--------------------------------------------------------------

  static double _time(

      Duration elapsed,

      Duration timeout) {

    final ratio =

        elapsed.inMilliseconds /

            timeout.inMilliseconds;

    if (ratio <= 0.20) return 100;

    if (ratio <= 0.40) return 95;

    if (ratio <= 0.60) return 90;

    if (ratio <= 0.80) return 80;

    if (ratio <= 1.00) return 70;

    return 60;

  }

}