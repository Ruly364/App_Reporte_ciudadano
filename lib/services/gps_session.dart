import 'dart:async';

import '../models/gps_capture_progress.dart';
import '../models/gps_capture_report.dart';
import '../models/gps_capture_session.dart';
import '../models/gps_configuration.dart';
import '../models/gps_dashboard.dart';
import '../models/gps_metadata.dart';
import '../models/gps_profile.dart';
import '../models/gps_statistics.dart';
import '../models/gps_state.dart';
import '../models/location_result.dart';

import '../models/location_source.dart';
import 'gps_scoring.dart';
import 'gps_window_scoring.dart';
import 'location_service.dart';

/// ===============================================================
/// GPS SESSION
/// ---------------------------------------------------------------
///
/// Núcleo del GPS Engine.
///
/// Responsabilidades:
///
/// • Controlar una sesión de captura
/// • Administrar el Stream GPS
/// • Calcular Score
/// • Elegir la mejor ventana
/// • Generar Progress
/// • Generar Report
/// • Generar Session
///
/// ===============================================================

class GpsSession {

  //--------------------------------------------------------------
  // CONFIGURACIÓN
  //--------------------------------------------------------------

  final GpsProfile profile;
  final bool continuous;

  late final GpsConfiguration configuration;

  //--------------------------------------------------------------
  // ESTADO
  //--------------------------------------------------------------

  GpsState _state = GpsState.idle;

  GpsState get state => _state;

  //--------------------------------------------------------------
  // STREAM GPS
  //--------------------------------------------------------------

  StreamSubscription<LocationResult>? _subscription;

  //--------------------------------------------------------------
  // HISTORIAL
  //--------------------------------------------------------------

  final List<LocationResult> _history = [];

  List<LocationResult> get history =>
      List.unmodifiable(_history);

  //--------------------------------------------------------------
  // MEJOR VENTANA
  //--------------------------------------------------------------

  List<LocationResult> _bestWindow = [];

  List<LocationResult> get bestWindow =>
      List.unmodifiable(_bestWindow);

  //--------------------------------------------------------------
  // ESTADÍSTICAS
  //--------------------------------------------------------------

  final GpsStatistics statistics = GpsStatistics();

  //--------------------------------------------------------------
  // LECTURAS
  //--------------------------------------------------------------

  LocationResult? _current;

  LocationResult? get current => _current;

  LocationResult? _best;

  LocationResult? get best => _best;

  //--------------------------------------------------------------
  // TIEMPO
  //--------------------------------------------------------------

  late DateTime _startTime;

  Timer? _timeoutTimer;

  Timer? _refinementTimer;

  //--------------------------------------------------------------
  // SCORE
  //--------------------------------------------------------------

  double _score = 0;

  double get score => _score;

  //--------------------------------------------------------------
  // EVENTOS
  //--------------------------------------------------------------

  final StreamController<GpsCaptureProgress>
  _progressController =
  StreamController.broadcast();

  Stream<GpsCaptureProgress> get progressStream =>
      _progressController.stream;

  //--------------------------------------------------------------
  // FINALIZACIÓN
  //--------------------------------------------------------------

  Completer<GpsCaptureSession> _sessionCompleter =
  Completer<GpsCaptureSession>();

  Future<GpsCaptureSession> get completed =>
      _sessionCompleter.future;

  //--------------------------------------------------------------
  // CONSTRUCTOR
  //--------------------------------------------------------------

  GpsSession({
    this.profile = GpsProfile.altaPrecision,
    this.continuous = false,
  }) {
    configuration = profile.configuration;
  }

  //--------------------------------------------------------------
  // ¿ESTÁ EJECUTÁNDOSE?
  //--------------------------------------------------------------

  bool get isRunning {
    return _subscription != null;
  }

  //--------------------------------------------------------------
  // DURACIÓN
  //--------------------------------------------------------------

  Duration get elapsed {
    if (_state == GpsState.idle) {
      return Duration.zero;
    }

    return DateTime.now().difference(_startTime);
  }

  //--------------------------------------------------------------
  // INICIAR SESIÓN
  //--------------------------------------------------------------

  Future<void> start() async {
    if (isRunning) {
      return;
    }

    final permission =
    await LocationService.ensurePermission();

    if (!permission) {
      _state = GpsState.error;

      _notify();

      return;
    }

    _state = GpsState.warmingUp;

    _history.clear();

    _bestWindow.clear();

    _current = null;

    _best = null;

    _score = 0;

    statistics.start();

    _startTime = DateTime.now();

    //----------------------------------------------------------
    // Timeout general
    //----------------------------------------------------------

    //----------------------------------------------------------
// Timeout general
//----------------------------------------------------------

    _timeoutTimer = Timer(
      configuration.timeout,
          () {
        if (_state == GpsState.completed ||
            _state == GpsState.cancelled) {
          return;
        }

        // En modo continuo no apagamos el GPS por el
        // timeout de adquisición.
        if (continuous) {
          return;
        }

        _state = GpsState.timeout;

        _finish();
      },
    );

    //----------------------------------------------------------
    // Escuchar GPS
    //----------------------------------------------------------

    _subscription =

        LocationService.listen().listen(

          _onLocation,

          onError: (error) {
            _state = GpsState.error;

            _notify();
          },

          cancelOnError: false,

        );

    _notify();
  }

  //--------------------------------------------------------------
  // NUEVA LECTURA GPS
  //--------------------------------------------------------------

  void _onLocation(LocationResult location,) {
    //----------------------------------------------------------
    // Guardar lectura
    //----------------------------------------------------------

    _current = location;

    _history.add(location);

    //----------------------------------------------------------
    // Actualizar estadísticas
    //----------------------------------------------------------

    statistics.addReading(

      accuracy: location.accuracy,

      speed: location.speed,

      satellites: location.satellites,

      source: location.source,

      quality: location.quality,

    );

    //----------------------------------------------------------
    // Todavía no existe ventana suficiente
    //----------------------------------------------------------

    if (_history.length <

        configuration.scoringWindowSize) {
      _notify();

      return;
    }

    //----------------------------------------------------------
    // Buscar mejor ventana
    //----------------------------------------------------------

    final window =

    GpsWindowScoring.bestWindow(

      history: _history,

      windowSize:
      configuration.scoringWindowSize,

      elapsed: elapsed,

      configuration: configuration,

    );

    _bestWindow = window;

    //----------------------------------------------------------
    // Punto representativo
    //----------------------------------------------------------

    _best =

        GpsWindowScoring.representative(

          window,

        );

    //----------------------------------------------------------
    // Score
    //----------------------------------------------------------

    _score =

        GpsScoring.calculate(

          history: window,

          elapsed: elapsed,

          configuration: configuration,

        );

    //----------------------------------------------------------
    // Cambiar estados
    //----------------------------------------------------------

    if (_score >= 70 &&
        _state == GpsState.warmingUp) {
      _state = GpsState.searching;
    }

    if (_score >= 85 &&
        _state == GpsState.searching) {
      _state = GpsState.refining;

      _startRefinement();
    }

    //----------------------------------------------------------
    // Actualizar Dashboard
    //----------------------------------------------------------

    _notify();
  }

  //--------------------------------------------------------------
  // REFINAMIENTO
  //--------------------------------------------------------------

  void _startRefinement() {
    if (_refinementTimer != null) {
      return;
    }

    _refinementTimer = Timer(
      configuration.refinementTime,
          () {
        if (_state == GpsState.cancelled) {
          return;
        }

        _state = GpsState.ready;

        // ==========================================================
        // MODO CONTINUO
        // ==========================================================
        //
        // La sesión permanece escuchando el GPS.
        //
        // Esto será utilizado posteriormente para la captura
        // de múltiples puntos mientras el brigadista se desplaza.
        //
        if (continuous) {
          _notify();
          return;
        }

        // ==========================================================
        // MODO CAPTURA PUNTUAL
        // ==========================================================

        _finish();
      },
    );
  }

  //--------------------------------------------------------------
  // NOTIFICAR CAMBIOS
  //--------------------------------------------------------------

  void _notify() {
    if (_progressController.isClosed) {
      return;
    }

    _progressController.add(

      GpsCaptureProgress(

        current: _current,

        best: _best,

        dashboard: _buildDashboard(),

      ),

    );
  }

  //--------------------------------------------------------------
  // DASHBOARD
  //--------------------------------------------------------------

  GpsDashboard _buildDashboard() {
    return GpsDashboard(

      state: _state,

      score: _score,

      currentAccuracy:

      _current?.accuracy ?? 0,

      bestAccuracy:

      _best?.accuracy ?? 0,

      confidence:

      _calculateConfidence(),

      health:

      _calculateHealth(),

      readings:

      _history.length,

      satellites:

      _best?.satellites ?? 0,

      elapsed:

      elapsed,

      provider:

      _providerName(),

      message:

      _statusMessage(),

      canFinish:

      _canFinish(),

    );
  }

  //--------------------------------------------------------------
  // CONFIANZA
  //--------------------------------------------------------------

  double _calculateConfidence() {
    if (_score <= 0) {
      return 0;
    }

    if (_score >= 100) {
      return 100;
    }

    return _score;
  }

  //--------------------------------------------------------------
  // SALUD GPS
  //--------------------------------------------------------------

  double _calculateHealth() {
    if (_best == null) {
      return 0;
    }

    final accuracy = _best!.accuracy;

    if (accuracy <= 2) return 100;

    if (accuracy <= 3) return 98;

    if (accuracy <= 5) return 95;

    if (accuracy <= 8) return 90;

    if (accuracy <= 10) return 85;

    if (accuracy <= 15) return 75;

    if (accuracy <= 20) return 60;

    return 40;
  }

  //--------------------------------------------------------------
  // PROVEEDOR
  //--------------------------------------------------------------

  String _providerName() {
    if (_best == null) {
      return "Sin GPS";
    }

    switch (_best!.source) {
      case LocationSource.androidGps:
        return "GPS Android";

      case LocationSource.network:
        return "Red";

      case LocationSource.garmin:
        return "Garmin";

      case LocationSource.rtk:
        return "RTK";

      case LocationSource.unknown:
        return "Desconocido";
    }
  }

  //--------------------------------------------------------------
  // MENSAJE
  //--------------------------------------------------------------

  String _statusMessage() {
    switch (_state) {
      case GpsState.idle:
        return "Motor detenido";

      case GpsState.warmingUp:
        return "Inicializando GPS...";

      case GpsState.searching:
        return "Buscando mejor posición...";

      case GpsState.refining:
        return "Refinando precisión...";

      case GpsState.ready:
        return "Precisión alcanzada.";

      case GpsState.completed:
        return "Captura finalizada.";

      case GpsState.timeout:
        return "Tiempo agotado.";

      case GpsState.cancelled:
        return "Captura cancelada.";

      case GpsState.error:
        return "Error GPS.";
    }
  }

  //--------------------------------------------------------------
  // ¿PODEMOS FINALIZAR?
  //--------------------------------------------------------------

  bool _canFinish() {
    if (_best == null) {
      return false;
    }

    if (_state == GpsState.ready) {
      return true;
    }

    return _best!.accuracy <=

        configuration.targetAccuracy;
  }

  //--------------------------------------------------------------
  // FINALIZAR CAPTURA
  //--------------------------------------------------------------

  void _finish() {

    //----------------------------------------------------------
    // Evitar ejecutar dos veces
    //----------------------------------------------------------

    if (_sessionCompleter.isCompleted) {

      return;

    }

    //----------------------------------------------------------
    // Detener timers
    //----------------------------------------------------------

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _refinementTimer?.cancel();
    _refinementTimer = null;

    //----------------------------------------------------------
    // Detener GPS
    //----------------------------------------------------------

    _subscription?.cancel();
    _subscription = null;

    //----------------------------------------------------------
    // Finalizar estadísticas
    //----------------------------------------------------------

    statistics.finish();

    //----------------------------------------------------------
    // Estado final
    //----------------------------------------------------------

    if (_state != GpsState.timeout &&
        _state != GpsState.cancelled &&
        _state != GpsState.error) {

      _state = GpsState.completed;

    }

    //----------------------------------------------------------
    // Crear sesión
    //----------------------------------------------------------

    final session = _buildSession();

    //----------------------------------------------------------
    // Notificar UI
    //----------------------------------------------------------

    _notify();

    //----------------------------------------------------------
    // Completar Future
    //----------------------------------------------------------

    _sessionCompleter.complete(session);

  }

  //--------------------------------------------------------------
  // CONSTRUIR SESIÓN
  //--------------------------------------------------------------

  GpsCaptureSession _buildSession() {

    final metadata = _buildMetadata();

    final report = _buildReport(metadata);

    return GpsCaptureSession(

      metadata: metadata,

      report: report,

      history: List<LocationResult>.from(_history),

      bestWindow: List<LocationResult>.from(_bestWindow),

      statistics: statistics.copy(),

    );

  }

  //--------------------------------------------------------------
  // METADATA
  //--------------------------------------------------------------

  GpsMetadata _buildMetadata() {

    return GpsMetadata(

      provider: _providerName(),

      manufacturer: "Android",

      model: "Unknown",

      device: "Android",

      osVersion: "Unknown",

      appVersion: "1.0.0",

      satellites: _best?.satellites ?? 0,

      hdop: _best?.hdop,

      vdop: _best?.vdop,

      pdop: _best?.pdop,

      rtkFix: _best?.rtkFix ?? false,

      externalReceiver:

      _best?.source == LocationSource.garmin ||

          _best?.source == LocationSource.rtk,

      timestamp: DateTime.now(),

    );

  }

  //--------------------------------------------------------------
  // REPORTE
  //--------------------------------------------------------------

  GpsCaptureReport _buildReport(

      GpsMetadata metadata,

      ) {

    return GpsCaptureReport(

      metadata: metadata,

      state: _state,

      location: _best,

      score: _score,

      confidence: _calculateConfidence(),

      health: _calculateHealth(),

      elapsed: elapsed,

      totalReadings: _history.length,

      windowSize: _bestWindow.length,

      averageAccuracy:

      GpsWindowScoring.averageAccuracy(

        _bestWindow,

      ),

      bestAccuracy:

      GpsWindowScoring.bestAccuracy(

        _bestWindow,

      ),

      averageDistance:

      GpsWindowScoring.averageDistance(

        _bestWindow,

      ),

      timestamp: DateTime.now(),

    );

  }

  //--------------------------------------------------------------
  // CANCELAR CAPTURA
  //--------------------------------------------------------------

  Future<void> cancel() async {

    if (_state == GpsState.completed ||
        _state == GpsState.cancelled) {

      return;

    }

    _state = GpsState.cancelled;

    _finish();

  }

  //--------------------------------------------------------------
  // REINICIAR SESIÓN
  //--------------------------------------------------------------

  void reset() {

    //----------------------------------------------------------
    // Detener timers
    //----------------------------------------------------------

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _refinementTimer?.cancel();
    _refinementTimer = null;

    //----------------------------------------------------------
    // Detener GPS
    //----------------------------------------------------------

    _subscription?.cancel();
    _subscription = null;

    //----------------------------------------------------------
    // Reiniciar estado
    //----------------------------------------------------------

    _state = GpsState.idle;

    //----------------------------------------------------------
    // Reiniciar datos
    //----------------------------------------------------------

    _history.clear();

    _bestWindow.clear();

    _current = null;

    _best = null;

    _score = 0;

    _sessionCompleter = Completer<GpsCaptureSession>();

    statistics.start();

    _notify();

  }

  //--------------------------------------------------------------
  // LIBERAR RECURSOS
  //--------------------------------------------------------------

  Future<void> dispose() async {

    await _subscription?.cancel();

    _subscription = null;

    _timeoutTimer?.cancel();

    _timeoutTimer = null;

    _refinementTimer?.cancel();

    _refinementTimer = null;

    if (!_progressController.isClosed) {

      await _progressController.close();

    }

  }

  //--------------------------------------------------------------
  // ¿EXISTE MEJOR UBICACIÓN?
  //--------------------------------------------------------------

  bool get hasBestLocation {

    return _best != null;

  }

  //--------------------------------------------------------------
  // ¿EXISTE HISTORIAL?
  //--------------------------------------------------------------

  bool get hasHistory {

    return _history.isNotEmpty;

  }

  //--------------------------------------------------------------
  // TOTAL DE LECTURAS
  //--------------------------------------------------------------

  int get totalReadings {

    return _history.length;

  }

  //--------------------------------------------------------------
  // ACCURACY ACTUAL
  //--------------------------------------------------------------

  double get currentAccuracy {

    return _current?.accuracy ?? 999;

  }

  //--------------------------------------------------------------
  // MEJOR ACCURACY
  //--------------------------------------------------------------

  double get bestAccuracy {

    return _best?.accuracy ?? 999;

  }

  //--------------------------------------------------------------
  // SATÉLITES
  //--------------------------------------------------------------

  int get satellites {

    return _best?.satellites ?? 0;

  }

  //--------------------------------------------------------------
  // LATITUD
  //--------------------------------------------------------------

  double? get latitude {

    return _best?.latitude;

  }

  //--------------------------------------------------------------
  // LONGITUD
  //--------------------------------------------------------------

  double? get longitude {

    return _best?.longitude;

  }

  //--------------------------------------------------------------
  // ALTITUD
  //--------------------------------------------------------------

  double? get altitude {

    return _best?.altitude;

  }

  //--------------------------------------------------------------
  // DASHBOARD ACTUAL
  //--------------------------------------------------------------

  GpsDashboard get dashboard {

    return _buildDashboard();

  }

  //--------------------------------------------------------------
  // PROGRESO ACTUAL
  //--------------------------------------------------------------

  GpsCaptureProgress get progress {

    return GpsCaptureProgress(

      current: _current,

      best: _best,

      dashboard: dashboard,

    );

  }

  //--------------------------------------------------------------
  // RESUMEN DE LA SESIÓN
  //--------------------------------------------------------------

  Map<String, dynamic> summary() {

    return {

      "state": _state.name,

      "score": _score,

      "elapsedSeconds": elapsed.inSeconds,

      "readings": _history.length,

      "bestAccuracy": bestAccuracy,

      "currentAccuracy": currentAccuracy,

      "satellites": satellites,

      "latitude": latitude,

      "longitude": longitude,

      "provider": _providerName(),

      "canFinish": _canFinish(),

    };

  }

  //--------------------------------------------------------------
  // DIAGNÓSTICO
  //--------------------------------------------------------------

  Map<String, dynamic> diagnostics() {

    return {

      "configuration": {

        "profile": profile.name,

        "targetAccuracy":
        configuration.targetAccuracy,

        "windowSize":
        configuration.scoringWindowSize,

        "stableReadings":
        configuration.stableReadings,

        "timeout":
        configuration.timeout.inSeconds,

        "refinement":
        configuration.refinementTime.inSeconds,

      },

      "statistics":

      statistics.toJson(),

      "dashboard":

      dashboard.toJson(),

      "historySize":

      _history.length,

      "bestWindowSize":

      _bestWindow.length,

    };

  }

  //--------------------------------------------------------------
  // HISTORIAL INMUTABLE
  //--------------------------------------------------------------

  List<LocationResult> exportHistory() {

    return List<LocationResult>.from(

      _history,

    );

  }

  //--------------------------------------------------------------
  // EXPORTAR MEJOR VENTANA
  //--------------------------------------------------------------

  List<LocationResult> exportBestWindow() {

    return List<LocationResult>.from(

      _bestWindow,

    );

  }

  //--------------------------------------------------------------
  // LIMPIAR HISTORIAL
  //--------------------------------------------------------------

  void clearHistory() {

    _history.clear();

    _bestWindow.clear();

    _notify();

  }

  //--------------------------------------------------------------
  // VALIDACIONES
  //--------------------------------------------------------------

  bool get hasEnoughReadings {

    return _history.length >=

        configuration.scoringWindowSize;

  }

  bool get isReady {

    return _state == GpsState.ready;

  }

  bool get isCompleted {

    return _state == GpsState.completed;

  }

  bool get isCancelled {

    return _state == GpsState.cancelled;

  }

  bool get isTimeout {

    return _state == GpsState.timeout;

  }

  bool get hasError {

    return _state == GpsState.error;

  }

  //--------------------------------------------------------------
  // SCORE NORMALIZADO
  //--------------------------------------------------------------

  double get normalizedScore {

    return (_score / 100.0)

        .clamp(0.0, 1.0);

  }

  //--------------------------------------------------------------
  // PORCENTAJE DE PROGRESO
  //--------------------------------------------------------------

  double get progressPercent {

    final total =

        configuration.timeout.inMilliseconds;

    final current =

        elapsed.inMilliseconds;

    return (current / total)

        .clamp(0.0, 1.0);

  }

  //--------------------------------------------------------------
  // TEXTO DEL SCORE
  //--------------------------------------------------------------

  String get scoreLabel {

    if (_score >= 95) {

      return "Excelente";

    }

    if (_score >= 85) {

      return "Muy bueno";

    }

    if (_score >= 70) {

      return "Bueno";

    }

    if (_score >= 50) {

      return "Regular";

    }

    return "Bajo";

  }

  //--------------------------------------------------------------
  // INDICADOR DE ESTABILIDAD
  //--------------------------------------------------------------

  bool get isStable {

    if (_best == null) {

      return false;

    }

    return _best!.accuracy <=

        configuration.targetAccuracy;

  }

  //--------------------------------------------------------------
  // SCORE EN PORCENTAJE
  //--------------------------------------------------------------

  String get scorePercent {

    return "${_score.toStringAsFixed(1)} %";

  }

  //--------------------------------------------------------------
  // ACCURACY FORMATEADO
  //--------------------------------------------------------------

  String get accuracyLabel {

    if (_best == null) {

      return "--";

    }

    return "${_best!.accuracy.toStringAsFixed(2)} m";

  }

  //--------------------------------------------------------------
  // COORDENADAS
  //--------------------------------------------------------------

  String get coordinateLabel {

    if (_best == null) {

      return "--";

    }

    return "${_best!.latitude.toStringAsFixed(6)}, "
        "${_best!.longitude.toStringAsFixed(6)}";

  }

  //--------------------------------------------------------------
  // LAT/LON
  //--------------------------------------------------------------

  String get latitudeLabel {

    return _best == null
        ? "--"
        : _best!.latitude.toStringAsFixed(6);

  }

  String get longitudeLabel {

    return _best == null
        ? "--"
        : _best!.longitude.toStringAsFixed(6);

  }

  //--------------------------------------------------------------
  // INFORMACIÓN RÁPIDA
  //--------------------------------------------------------------

  Map<String, String> quickInfo() {

    return {

      "Estado": _state.name,

      "Score": scorePercent,

      "Accuracy": accuracyLabel,

      "Proveedor": _providerName(),

      "Lecturas": _history.length.toString(),

      "Satélites": satellites.toString(),

      "Tiempo": "${elapsed.inSeconds}s",

      "Perfil": profile.name,

    };

  }

  //--------------------------------------------------------------
  // INFORMACIÓN EXTENDIDA
  //--------------------------------------------------------------

  Map<String, dynamic> extendedInfo() {

    return {

      ...summary(),

      "dashboard": dashboard.toJson(),

      "statistics": statistics.toJson(),

      "historyCount": _history.length,

      "bestWindowCount": _bestWindow.length,

      "normalizedScore": normalizedScore,

      "progress": progressPercent,

      "stable": isStable,

      "ready": isReady,

      "completed": isCompleted,

    };

  }

  //--------------------------------------------------------------
  // LOG
  //--------------------------------------------------------------

  String buildLog() {

    final buffer = StringBuffer();

    buffer.writeln("========== GPS SESSION ==========");

    buffer.writeln("Estado: ${_state.name}");

    buffer.writeln("Perfil: ${profile.name}");

    buffer.writeln("Score: ${_score.toStringAsFixed(2)}");

    buffer.writeln("Accuracy: $accuracyLabel");

    buffer.writeln("Proveedor: ${_providerName()}");

    buffer.writeln("Tiempo: ${elapsed.inSeconds}s");

    buffer.writeln("Lecturas: ${_history.length}");

    buffer.writeln("Ventana: ${_bestWindow.length}");

    buffer.writeln("Satélites: $satellites");

    if (_best != null) {

      buffer.writeln(
          "Latitud: ${_best!.latitude}");

      buffer.writeln(
          "Longitud: ${_best!.longitude}");

      buffer.writeln(
          "Altitud: ${_best!.altitude}");

    }

    buffer.writeln("===============================");

    return buffer.toString();

  }

  //--------------------------------------------------------------
  // DEBUG
  //--------------------------------------------------------------

  @override
  String toString() {

    return buildLog();

  }


  //--------------------------------------------------------------
  // ¿EXISTE UNA SESIÓN ACTIVA?
  //--------------------------------------------------------------

  bool get hasActiveSession {

    return isRunning &&
        _state != GpsState.completed &&
        _state != GpsState.cancelled &&
        _state != GpsState.timeout &&
        _state != GpsState.error;

  }

  //--------------------------------------------------------------
  // SESIÓN TERMINADA
  //--------------------------------------------------------------

  bool get hasFinished {

    return _state == GpsState.completed ||
        _state == GpsState.timeout ||
        _state == GpsState.cancelled ||
        _state == GpsState.error;

  }

  //--------------------------------------------------------------
  // ÚLTIMA UBICACIÓN
  //--------------------------------------------------------------

  LocationResult? get lastLocation {

    if (_history.isEmpty) {

      return null;

    }

    return _history.last;

  }

  //--------------------------------------------------------------
  // MEJOR UBICACIÓN
  //--------------------------------------------------------------

  LocationResult? get bestLocation {

    return _best;

  }

  //--------------------------------------------------------------
  // LIMPIAR RESULTADOS
  //--------------------------------------------------------------

  void clearResults() {

    _history.clear();

    _bestWindow.clear();

    _current = null;

    _best = null;

    _score = 0;

    _notify();

  }

  //--------------------------------------------------------------
  // EXPORTAR REPORTE RÁPIDO
  //--------------------------------------------------------------

  Map<String, dynamic> export() {

    return {

      "state": _state.name,

      "score": _score,

      "elapsed": elapsed.inMilliseconds,

      "history": _history.length,

      "window": _bestWindow.length,

      "statistics": statistics.toJson(),

      "dashboard": dashboard.toJson(),

    };

  }

}





