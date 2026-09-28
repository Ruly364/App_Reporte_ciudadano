/// ===============================================================
/// LOCATION SOURCE
/// ---------------------------------------------------------------
/// Indica el origen de la ubicación.
/// ===============================================================

enum LocationSource {

  /// GPS interno Android
  androidGps,

  /// GPS por red (si algún día se habilita)
  network,

  /// Garmin Bluetooth
  garmin,

  /// Receptor GNSS RTK
  rtk,

  /// Desconocido
  unknown,

}