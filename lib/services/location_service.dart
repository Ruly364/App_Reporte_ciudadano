import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/location_quality.dart';
import '../models/location_result.dart';
import '../models/location_source.dart';

/// ===============================================================
/// LOCATION SERVICE
/// ===============================================================
///
/// Servicio central de ubicación.
///
/// OBJETIVOS:
/// - Obtener rápidamente una primera posición cuando sea posible.
/// - Mantener alta precisión durante la captura.
/// - Funcionar completamente sin Internet.
/// - No depender de conectividad para obtener coordenadas.
/// - Mantener un stream continuo para GpsSession.
/// - No reiniciar innecesariamente el GPS.
/// - Permitir adquisición GNSS aun sin Wi-Fi ni datos móviles.
/// ===============================================================

class LocationService {
  LocationService._();

  // ==============================================================
  // CONFIGURACIÓN
  // ==============================================================

  /// Tiempo máximo para la adquisición de una posición actual.
  ///
  /// Se aumenta respecto a los 12 segundos anteriores porque,
  /// cuando el dispositivo no dispone de asistencia de red,
  /// Android puede necesitar más tiempo para obtener un fix GNSS.
  ///
  /// IMPORTANTE:
  /// Esto NO significa que el formulario deba quedar bloqueado
  /// durante este tiempo. GpsSession continúa trabajando mediante
  /// el stream y la interfaz puede mostrar "Obteniendo ubicación".
  static const Duration currentTimeout =
  Duration(seconds: 30);

  /// Distancia mínima para emitir una nueva lectura.
  ///
  /// 2 metros permite posteriormente trabajar con múltiples puntos
  /// mientras el brigadista se encuentra en movimiento.
  static const int defaultDistanceFilter = 2;

  // ==============================================================
  // PERMISOS
  // ==============================================================

  static Future<bool> ensurePermission() async {
    final enabled =
    await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      return false;
    }

    var permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ==============================================================
  // ÚLTIMA POSICIÓN CONOCIDA
  // ==============================================================

  /// Obtiene la última posición conocida del dispositivo.
  ///
  /// IMPORTANTE:
  /// Esta posición NO debe utilizarse como coordenada definitiva
  /// de un nuevo reporte si existe una posición actual disponible.
  ///
  /// Sirve principalmente para poder inicializar rápidamente la
  /// interfaz mientras el GPS obtiene una lectura actual.
  static Future<LocationResult?> lastKnown() async {
    if (!await ensurePermission()) {
      return null;
    }

    try {
      final position =
      await Geolocator.getLastKnownPosition();

      if (position == null) {
        return null;
      }

      return _convert(position);
    } catch (_) {
      return null;
    }
  }

  // ==============================================================
  // POSICIÓN ACTUAL
  // ==============================================================

  /// Obtiene una posición GPS actual.
  ///
  /// NO depende de Wi-Fi ni de datos móviles.
  ///
  /// Cuando existe conectividad, Android puede obtener el fix
  /// más rápidamente mediante asistencia de ubicación.
  ///
  /// Sin conectividad, el receptor GNSS puede continuar trabajando
  /// directamente con los satélites.
  ///
  /// No utilizamos una posición antigua como sustituto de la
  /// posición actual.
  static Future<LocationResult?> current() async {
    if (!await ensurePermission()) {
      return null;
    }

    try {
      final position =
      await Geolocator.getCurrentPosition(
        desiredAccuracy:
        LocationAccuracy.best,
        timeLimit:
        currentTimeout,
      );

      return _convert(position);
    } on TimeoutException {
      // ----------------------------------------------------------
      // IMPORTANTE
      // ----------------------------------------------------------
      //
      // No intentamos fabricar una coordenada ni utilizar una
      // posición antigua como si fuera actual.
      //
      // GpsSession continuará utilizando el stream GPS para
      // seguir adquiriendo y refinando la posición.
      //
      return null;
    } catch (_) {
      return null;
    }
  }

  // ==============================================================
  // STREAM GPS
  // ==============================================================

  /// Stream continuo de posiciones GPS.
  ///
  /// Este método es utilizado por GpsSession.
  ///
  /// El stream NO depende de Internet.
  ///
  /// La conectividad puede ayudar a Android a adquirir la primera
  /// posición más rápidamente, pero una vez iniciado el GNSS,
  /// las coordenadas pueden obtenerse directamente de los satélites.
  static Stream<LocationResult> listen({
    LocationAccuracy accuracy =
        LocationAccuracy.best,
    int distanceFilter =
        defaultDistanceFilter,
  }) {
    final settings = AndroidSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,

      // ----------------------------------------------------------
      // No forzamos Android Location Manager.
      //
      // Dejamos que Geolocator utilice el proveedor recomendado
      // por Android para obtener la mejor ubicación disponible.
      // ----------------------------------------------------------
      forceLocationManager: false,

      // ----------------------------------------------------------
      // Solicitud periódica de actualización.
      //
      // El distanceFilter continúa siendo el criterio principal
      // para las posiciones durante el desplazamiento.
      // ----------------------------------------------------------
      intervalDuration:
      const Duration(seconds: 1),
    );

    return Geolocator
        .getPositionStream(
      locationSettings: settings,
    )
        .map(_convert);
  }

  // ==============================================================
  // CONVERSIÓN
  // ==============================================================

  static LocationResult _convert(
      Position position,
      ) {
    return LocationResult(
      latitude:
      position.latitude,

      longitude:
      position.longitude,

      altitude:
      position.altitude,

      accuracy:
      position.accuracy,

      verticalAccuracy:
      position.altitudeAccuracy,

      heading:
      position.heading,

      speed:
      position.speed,

      source:
      LocationSource.androidGps,

      quality:
      _qualityFromAccuracy(
        position.accuracy,
      ),

      // Geolocator no proporciona directamente el número de
      // satélites mediante Position.
      satellites: 0,

      hdop: null,
      vdop: null,
      pdop: null,

      rtkFix: false,

      timestamp:
      position.timestamp ??
          DateTime.now(),
    );
  }

  // ==============================================================
  // CALIDAD
  // ==============================================================

  static LocationQuality _qualityFromAccuracy(
      double accuracy,
      ) {
    if (accuracy <= 3) {
      return LocationQuality.excellent;
    }

    if (accuracy <= 5) {
      return LocationQuality.good;
    }

    if (accuracy <= 10) {
      return LocationQuality.fair;
    }

    return LocationQuality.poor;
  }
}