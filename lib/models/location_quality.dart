/// ===============================================================
/// LOCATION QUALITY
/// ---------------------------------------------------------------
/// Calidad de la ubicación según el Accuracy.
/// ===============================================================

enum LocationQuality {

  /// <= 3 m
  excellent,

  /// <= 5 m
  veryGood,

  /// <= 10 m
  good,

  /// <= 20 m
  fair,

  /// > 20 m
  poor,

  /// Desconocida
  unknown,

}