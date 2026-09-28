import 'gps_configuration.dart';

/// ===============================================================
/// GPS PROFILE
/// ---------------------------------------------------------------
///
/// Perfiles predefinidos del motor GPS.
///
/// Cada perfil representa un escenario de captura.
///
/// • Rápido
/// • Alta Precisión
/// • Bosque
/// • GNSS Externo
///
/// ===============================================================

enum GpsProfile {

  /// Captura rápida.
  rapido,

  /// Captura estándar.
  altaPrecision,

  /// Captura para zonas forestales.
  bosque,

  /// Receptor GNSS externo
  /// (Garmin, Bad Elf, RTK, etc.)
  gnssExterno,

}

extension GpsProfileExtension on GpsProfile {

  GpsConfiguration get configuration {

    switch (this) {

    //----------------------------------------------------------
    // RÁPIDO
    //----------------------------------------------------------

      case GpsProfile.rapido:

        return const GpsConfiguration(

          //------------------------------------------------------
          // Precisión
          //------------------------------------------------------

          targetAccuracy: 10.0,

          stableReadings: 2,

          scoringWindowSize: 3,

          //------------------------------------------------------
          // Tiempos
          //------------------------------------------------------

          refinementTime: Duration(seconds: 2),

          timeout: Duration(seconds: 10),

          //------------------------------------------------------
          // Pesos
          //------------------------------------------------------

          accuracyWeight: 0.40,

          stabilityWeight: 0.25,

          consistencyWeight: 0.20,

          timeWeight: 0.15,

        );

    //----------------------------------------------------------
    // ALTA PRECISIÓN
    //----------------------------------------------------------

      case GpsProfile.altaPrecision:

        return const GpsConfiguration(

          targetAccuracy: 5.0,

          stableReadings: 3,

          scoringWindowSize: 5,

          refinementTime: Duration(seconds: 5),

          timeout: Duration(seconds: 20),

          accuracyWeight: 0.40,

          stabilityWeight: 0.25,

          consistencyWeight: 0.20,

          timeWeight: 0.15,

        );

    //----------------------------------------------------------
    // BOSQUE
    //----------------------------------------------------------

      case GpsProfile.bosque:

        return const GpsConfiguration(

          targetAccuracy: 3.0,

          stableReadings: 4,

          scoringWindowSize: 8,

          refinementTime: Duration(seconds: 8),

          timeout: Duration(seconds: 35),

          accuracyWeight: 0.35,

          stabilityWeight: 0.30,

          consistencyWeight: 0.25,

          timeWeight: 0.10,

        );

    //----------------------------------------------------------
    // GNSS EXTERNO
    //----------------------------------------------------------

      case GpsProfile.gnssExterno:

        return const GpsConfiguration(

          targetAccuracy: 0.30,

          stableReadings: 5,

          scoringWindowSize: 10,

          refinementTime: Duration(seconds: 5),

          timeout: Duration(seconds: 30),

          accuracyWeight: 0.45,

          stabilityWeight: 0.20,

          consistencyWeight: 0.30,

          timeWeight: 0.05,

          minimumSatellites: 8,

          maximumHdop: 1.5,

          allowExternalGnss: true,

          allowInternalGps: false,

        );

    }

  }

}