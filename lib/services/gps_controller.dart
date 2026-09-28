import '../models/gps_capture_progress.dart';
import '../models/gps_capture_session.dart';
import '../models/gps_dashboard.dart';
import '../models/gps_profile.dart';
import '../models/gps_state.dart';

import 'gps_session.dart';

/// ===============================================================
/// GPS CONTROLLER
/// ---------------------------------------------------------------
///
/// Fachada del GPS Engine.
///
/// La UI únicamente interactúa con esta clase.
///
/// ReportePage
///        │
///        ▼
///  GpsController
///        │
///        ▼
///    GpsSession
///
/// El Controller permite dos modos:
///
/// 1. Captura puntual
///    - Obtiene una posición confiable.
///    - Finaliza la sesión.
///    - Comportamiento actual de la aplicación.
///
/// 2. Captura continua
///    - Mantiene la sesión GPS activa.
///    - Permite recibir múltiples posiciones.
///    - Preparado para el trabajo de campo en movimiento.
///
/// IMPORTANTE:
/// La activación del modo continuo se hará posteriormente desde
/// la lógica de captura. Por defecto permanece DESACTIVADO para
/// no alterar el comportamiento actual.
/// ===============================================================

class GpsController {
  //------------------------------------------------------------
  // SESIÓN
  //------------------------------------------------------------

  GpsSession _session;

  //------------------------------------------------------------
  // CONFIGURACIÓN
  //------------------------------------------------------------

  /// Indica si el Controller trabaja en modo continuo.
  ///
  /// false:
  ///   captura puntual, comportamiento actual.
  ///
  /// true:
  ///   mantiene activa la sesión GPS para múltiples puntos.
  bool _continuous;

  //------------------------------------------------------------
  // RESULTADO FINAL
  //------------------------------------------------------------

  GpsCaptureSession? _captureSession;

  //------------------------------------------------------------
  // CONSTRUCTOR
  //------------------------------------------------------------

  GpsController({
    GpsProfile profile = GpsProfile.altaPrecision,
    bool continuous = false,
  })  : _continuous = continuous,
        _session = GpsSession(
          profile: profile,
          continuous: continuous,
        );

  //------------------------------------------------------------
  // MODO CONTINUO
  //------------------------------------------------------------

  /// Indica si actualmente está configurado para captura continua.
  bool get isContinuous => _continuous;

  //------------------------------------------------------------
  // STREAM
  //------------------------------------------------------------

  Stream<GpsCaptureProgress> get progressStream =>
      _session.progressStream;

  //------------------------------------------------------------
  // DASHBOARD
  //------------------------------------------------------------

  GpsDashboard get dashboard =>
      _session.dashboard;

  //------------------------------------------------------------
  // PROGRESS
  //------------------------------------------------------------

  GpsCaptureProgress get progress =>
      _session.progress;

  //------------------------------------------------------------
  // ESTADO
  //------------------------------------------------------------

  GpsState get state =>
      _session.state;

  //------------------------------------------------------------
  // SCORE
  //------------------------------------------------------------

  double get score =>
      _session.score;

  //------------------------------------------------------------
  // ¿ESTÁ EJECUTÁNDOSE?
  //------------------------------------------------------------

  bool get isRunning =>
      _session.isRunning;

  //------------------------------------------------------------
  // ¿PODEMOS FINALIZAR?
  //------------------------------------------------------------

  bool get canFinish =>
      dashboard.canFinish;

  //------------------------------------------------------------
  // SESIÓN FINAL
  //------------------------------------------------------------

  GpsCaptureSession? get captureSession =>
      _captureSession;

  //------------------------------------------------------------
  // CAPTURAR
  //------------------------------------------------------------

  /// Realiza una captura puntual.
  ///
  /// Este método conserva el comportamiento que ya tenía
  /// la aplicación.
  ///
  /// En este modo la sesión termina cuando alcanza las
  /// condiciones configuradas por GpsSession.
  Future<GpsCaptureSession> capture() async {
    if (_continuous) {
      throw StateError(
        'capture() no puede utilizarse en modo continuo. '
            'Utiliza startContinuous() y posteriormente stopContinuous().',
      );
    }

    _captureSession = null;

    await _session.start();

    _captureSession = await _session.completed;

    return _captureSession!;
  }

  //------------------------------------------------------------
  // INICIAR CAPTURA PUNTUAL
  //------------------------------------------------------------

  Future<void> start() async {
    if (_continuous) {
      throw StateError(
        'start() corresponde a una captura puntual. '
            'Utiliza startContinuous() para captura continua.',
      );
    }

    await _session.start();
  }

  //------------------------------------------------------------
  // INICIAR CAPTURA CONTINUA
  //------------------------------------------------------------

  /// Inicia una sesión GPS que permanecerá activa.
  ///
  /// Este método NO se utilizará todavía desde ReportePage.
  ///
  /// Queda preparado para la siguiente fase, donde podremos
  /// utilizarlo para:
  ///
  /// Punto 1
  /// Punto 2
  /// Punto 3
  /// Punto 4
  /// ...
  ///
  /// mientras el brigadista se desplaza.
  Future<void> startContinuous() async {
    if (_session.isRunning) {
      return;
    }

    _continuous = true;

    _captureSession = null;

    await _session.start();
  }

  //------------------------------------------------------------
  // DETENER CAPTURA CONTINUA
  //------------------------------------------------------------

  /// Detiene una sesión continua.
  ///
  /// La finalización real queda a cargo de GpsSession.
  Future<void> stopContinuous() async {
    if (!_continuous) {
      return;
    }

    await _session.cancel();

    _continuous = false;
  }

  //------------------------------------------------------------
  // CANCELAR
  //------------------------------------------------------------

  Future<void> cancel() async {
    await _session.cancel();
  }

  //------------------------------------------------------------
  // REINICIAR
  //------------------------------------------------------------

  void reset() {
    _captureSession = null;

    _session.reset();
  }

  //------------------------------------------------------------
  // CAMBIAR PERFIL
  //------------------------------------------------------------

  Future<void> changeProfile(
      GpsProfile profile,
      ) async {
    if (_session.isRunning) {
      throw StateError(
        'No es posible cambiar el perfil durante una captura.',
      );
    }

    _captureSession = null;

    await _session.dispose();

    _session = GpsSession(
      profile: profile,
      continuous: _continuous,
    );
  }

  //------------------------------------------------------------
  // CAMBIAR MODO CONTINUO
  //------------------------------------------------------------

  /// Cambia el modo de captura cuando la sesión no está activa.
  ///
  /// No reinicia una sesión que ya esté funcionando.
  void setContinuousMode(bool enabled) {
    if (_session.isRunning) {
      throw StateError(
        'No es posible cambiar el modo continuo durante '
            'una captura activa.',
      );
    }

    _continuous = enabled;
  }

  //------------------------------------------------------------
  // RESULTADO DISPONIBLE
  //------------------------------------------------------------

  bool get hasResult {
    return _captureSession != null;
  }

  //------------------------------------------------------------
  // ÚLTIMA SESIÓN
  //------------------------------------------------------------

  GpsCaptureSession? get result {
    return _captureSession;
  }

  //------------------------------------------------------------
  // INFORMACIÓN RÁPIDA
  //------------------------------------------------------------

  Map<String, dynamic> summary() {
    return {
      "state": state.name,
      "running": isRunning,
      "continuous": isContinuous,
      "score": score,
      "canFinish": canFinish,
      "hasResult": hasResult,
      "elapsed":
      dashboard.elapsed.inSeconds,
      "accuracy":
      dashboard.bestAccuracy,
      "confidence":
      dashboard.confidence,
      "health":
      dashboard.health,
      "readings":
      dashboard.readings,
      "satellites":
      dashboard.satellites,
    };
  }

  //------------------------------------------------------------
  // EXPORTAR DASHBOARD
  //------------------------------------------------------------

  GpsDashboard getDashboard() {
    return dashboard;
  }

  //------------------------------------------------------------
  // EXPORTAR PROGRESS
  //------------------------------------------------------------

  GpsCaptureProgress getProgress() {
    return progress;
  }

  //------------------------------------------------------------
  // EXPORTAR RESULTADO
  //------------------------------------------------------------

  GpsCaptureSession? export() {
    return _captureSession;
  }

  //------------------------------------------------------------
  // DISPOSE
  //------------------------------------------------------------

  Future<void> dispose() async {
    await _session.dispose();
  }

  //------------------------------------------------------------
  // DEBUG
  //------------------------------------------------------------

  @override
  String toString() {
    return '''

===============================

GPS CONTROLLER

===============================

Estado............. ${state.name}

Running............ $isRunning

Modo continuo..... $isContinuous

Score.............. ${score.toStringAsFixed(1)}

Accuracy........... ${dashboard.bestAccuracy.toStringAsFixed(2)} m

Confianza.......... ${dashboard.confidence.toStringAsFixed(1)} %

Salud.............. ${dashboard.health.toStringAsFixed(1)} %

Lecturas........... ${dashboard.readings}

Satélites.......... ${dashboard.satellites}

Tiempo............. ${dashboard.elapsed.inSeconds} s

Resultado.......... $hasResult

===============================

''';
  }
}