/// ===============================================================
/// GPS STATE
/// ---------------------------------------------------------------
/// Estados internos del GPS Engine.
/// ===============================================================

enum GpsState {

  /// Motor apagado
  idle,

  /// Calentando GPS
  warmingUp,

  /// Buscando satélites
  searching,

  /// Refinando precisión
  refining,

  /// Precisión alcanzada
  ready,

  /// Captura finalizada
  completed,

  /// Tiempo agotado
  timeout,

  /// Cancelado
  cancelled,

  /// Error
  error,

}