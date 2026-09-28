import '../models/gps_configuration.dart';
import '../models/location_result.dart';
import 'gps_scoring.dart';

/// ===============================================================
/// GPS WINDOW SCORING
/// ---------------------------------------------------------------
///
/// Evalúa ventanas móviles de lecturas GPS y selecciona
/// la mejor ventana según el algoritmo de Score.
///
/// Responsabilidades:
///
/// ✔ Construir ventanas
/// ✔ Calcular Score
/// ✔ Elegir la mejor ventana
/// ✔ Obtener el punto representativo
///
/// ===============================================================

class GpsWindowScoring {

  GpsWindowScoring._();

  //--------------------------------------------------------------
  // MEJOR VENTANA
  //--------------------------------------------------------------

  static List<LocationResult> bestWindow({

    required List<LocationResult> history,

    required int windowSize,

    required Duration elapsed,

    required GpsConfiguration configuration,

  }) {

    if (history.isEmpty) {

      return [];

    }

    if (history.length <= windowSize) {

      return List<LocationResult>.from(history);

    }

    double bestScore = -1;

    List<LocationResult> bestWindow = [];

    for (int i = 0;

    i <= history.length - windowSize;

    i++) {

      final window = history.sublist(

        i,

        i + windowSize,

      );

      final score =

      GpsScoring.calculate(

        history: window,

        elapsed: elapsed,

        configuration: configuration,

      );

      if (score > bestScore) {

        bestScore = score;

        bestWindow = window;

      }

    }

    return List<LocationResult>.from(bestWindow);

  }

  //--------------------------------------------------------------
  // PUNTO REPRESENTATIVO
  //--------------------------------------------------------------

  static LocationResult representative(

      List<LocationResult> window) {

    if (window.isEmpty) {

      throw Exception(

        "La ventana está vacía.",

      );

    }

    if (window.length == 1) {

      return window.first;

    }

    final c = centroid(window);

    double bestDistance = double.infinity;

    LocationResult best = window.first;

    for (final p in window) {

      final d =

      _distance(

        c.latitude,

        c.longitude,

        p.latitude,

        p.longitude,

      );

      if (d < bestDistance) {

        bestDistance = d;

        best = p;

      }

    }

    return best;

  }

  //--------------------------------------------------------------
  // CENTROIDE
  //--------------------------------------------------------------

  static ({double latitude,double longitude})

  centroid(

      List<LocationResult> window){

    double lat=0;

    double lon=0;

    for(final p in window){

      lat+=p.latitude;

      lon+=p.longitude;

    }

    return(

    latitude:lat/window.length,

    longitude:lon/window.length,

    );

  }

  //--------------------------------------------------------------
  // ACCURACY PROMEDIO
  //--------------------------------------------------------------

  static double averageAccuracy(

      List<LocationResult> window){

    if(window.isEmpty){

      return 999;

    }

    double total=0;

    for(final p in window){

      total+=p.accuracy;

    }

    return total/window.length;

  }

  //--------------------------------------------------------------
  // MEJOR ACCURACY
  //--------------------------------------------------------------

  static double bestAccuracy(

      List<LocationResult> window){

    if(window.isEmpty){

      return 999;

    }

    double best=

        window.first.accuracy;

    for(final p in window){

      if(p.accuracy<best){

        best=p.accuracy;

      }

    }

    return best;

  }

  //--------------------------------------------------------------
  // PEOR ACCURACY
  //--------------------------------------------------------------

  static double worstAccuracy(

      List<LocationResult> window){

    if(window.isEmpty){

      return 999;

    }

    double worst=

        window.first.accuracy;

    for(final p in window){

      if(p.accuracy>worst){

        worst=p.accuracy;

      }

    }

    return worst;

  }

  //--------------------------------------------------------------
  // DISTANCIA PROMEDIO AL CENTROIDE
  //--------------------------------------------------------------

  static double averageDistance(

      List<LocationResult> window){

    if(window.length<2){

      return 0;

    }

    final c=

    centroid(window);

    double total=0;

    for(final p in window){

      total+=

          _distance(

            c.latitude,

            c.longitude,

            p.latitude,

            p.longitude,

          );

    }

    return total/window.length;

  }

  //--------------------------------------------------------------
  // DISPERSIÓN
  //--------------------------------------------------------------

  static double dispersion(

      List<LocationResult> window){

    return averageDistance(window);

  }

  //--------------------------------------------------------------
  // DISTANCIA APROXIMADA
  //--------------------------------------------------------------

  static double _distance(

      double lat1,

      double lon1,

      double lat2,

      double lon2){

    final dx=

        (lat1-lat2)*111320;

    final dy=

        (lon1-lon2)*111320;

    return (dx*dx+dy*dy)

        .sqrt();

  }

}

extension on num{

  double sqrt(){

    return Math.sqrt(toDouble());

  }

}

class Math{

  static double sqrt(double x){

    if(x<=0){

      return 0;

    }

    double guess=x;

    for(int i=0;i<10;i++){

      guess=(guess+x/guess)/2;

    }

    return guess;

  }

}