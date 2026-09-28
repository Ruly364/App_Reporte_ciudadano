import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'services/catalogo_service.dart';
import 'models/tipo_plaga.dart';
import 'services/excel_service.dart';
import 'widgets/imagen_visor.dart';

class SupervisorPage extends StatefulWidget {
  const SupervisorPage({super.key});
  @override
  State<SupervisorPage> createState() => _SupervisorPageState();
}

class _SupervisorPageState extends State<SupervisorPage> {
  List _todosLosReportes = [];
  List _reportesFiltrados = [];
  List<TipoPlaga> tiposPlaga = [];

  // Buscador
  final _busquedaCtrl = TextEditingController();
  String _textoBusqueda = '';

  // Filtros
  String? filtroStatus;
  String? filtroPlaga;
  DateTime? filtroFechaInicio;
  DateTime? filtroFechaFin;
  String? filtroStatusRapido;

  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    cargarReportes();
    cargarTiposPlaga();
    _busquedaCtrl.addListener(_aplicarBusquedaLocal);
  }

  @override
  void dispose() {
    _busquedaCtrl.removeListener(_aplicarBusquedaLocal);
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarTiposPlaga() async {
    final lista = await CatalogoService.obtenerTiposPlaga();
    setState(() => tiposPlaga = lista);
  }

  Future<void> cargarReportes() async {
    setState(() => _cargando = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // El supervisor no filtra por estado (solo ve el suyo)


    final params = <String, String>{};

    if (filtroPlaga != null)
      params['tipoPlaga'] = filtroPlaga!;

    if (filtroFechaInicio != null)
      params['fechaInicio'] = filtroFechaInicio!.toIso8601String();

    if (filtroFechaFin != null)
      params['fechaFin'] = filtroFechaFin!.toIso8601String();


    final uri = Uri.parse('${ApiConfig.baseUrl}/reportes/supervisor')
        .replace(queryParameters: params);

    final response =
    await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _todosLosReportes = data;
        //_aplicarBusquedaLocal();
      });
      _aplicarFiltrosLocales();
    }

    setState(() => _cargando = false);
  }

  void _aplicarBusquedaLocal() {
    _textoBusqueda =
        _busquedaCtrl.text.toLowerCase().trim();

    _aplicarFiltrosLocales();
  }

  void _aplicarFiltrosLocales() {
    var lista = List.from(_todosLosReportes);

    // filtro rápido dashboard
    if (filtroStatusRapido != null) {
      lista = lista.where((r) {
        return (r['estado'] ?? '') == filtroStatusRapido;
      }).toList();
    }

    // búsqueda
    if (_textoBusqueda.isNotEmpty) {
      lista = lista.where((r) {
        return (r['folio'] ?? '')
            .toLowerCase()
            .contains(_textoBusqueda) ||
            (r['tipoPlaga'] ?? '')
                .toLowerCase()
                .contains(_textoBusqueda) ||
            (r['municipio'] ?? '')
                .toLowerCase()
                .contains(_textoBusqueda) ||
            (r['localidad'] ?? '')
                .toLowerCase()
                .contains(_textoBusqueda);
      }).toList();
    }

    setState(() {
      _reportesFiltrados = lista;
    });
  }



  Future<void> cambiarEstado(int id, String estado) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await http.put(
      Uri.parse('${ApiConfig.baseUrl}/reportes/$id/estado'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(estado),
    );
    cargarReportes();
  }

  Future<void> agregarComentario(int reporteId, String texto) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/reportes/$reporteId/comentarios'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'texto': texto}),
    );
    cargarReportes();
  }

  Color _colorStatus(String? status) {
    switch (status) {
      case 'Atendido':   return Colors.green;
      case 'En proceso': return Colors.orange;
      default:           return Colors.red;
    }
  }


  int _contarStatus(String status) {
    return _todosLosReportes
        .where((r) =>
    (r['estado'] ?? '').toString().toLowerCase() ==
        status.toLowerCase())
        .length;
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return '-';
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return fecha;
    }
  }

  bool get _hayFiltrosActivos =>
      filtroStatus != null ||
          filtroPlaga != null ||
          filtroFechaInicio != null ||
          filtroFechaFin != null;

  void _limpiarFiltros() {
    setState(() {
      filtroStatus = null;
      filtroPlaga = null;
      filtroFechaInicio = null;
      filtroFechaFin = null;
      filtroStatusRapido = null;
    });
    cargarReportes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Supervisor'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [

          //Boton excel descarga
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar a Excel',
            onPressed: _todosLosReportes.isEmpty
                ? null
                : () => ExcelService.exportarReportes(
              context: context,
              reportes: _todosLosReportes,
              nombreArchivo: 'reportes_Supervisor',
            ),
          ),

          if (_hayFiltrosActivos)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: 'Limpiar filtros',
              onPressed: _limpiarFiltros,
            ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtros',
                onPressed: _mostrarFiltros,
              ),
              if (_hayFiltrosActivos)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [

          // ── Buscador ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por folio, plaga, municipio…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _textoBusqueda.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _busquedaCtrl.clear(),
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),
          _statsStatus(),


          // ── Chips de filtros activos ──────────────────────────
          if (_hayFiltrosActivos)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  if (filtroStatus != null)
                    _chipFiltro('Status: $filtroStatus',
                            () => setState(() { filtroStatus = null; cargarReportes(); })),
                  if (filtroPlaga != null)
                    _chipFiltro('Plaga: $filtroPlaga',
                            () => setState(() { filtroPlaga = null; cargarReportes(); })),
                  if (filtroFechaInicio != null)
                    _chipFiltro(
                        'Desde: ${_formatearFecha(filtroFechaInicio!.toIso8601String())}',
                            () => setState(() { filtroFechaInicio = null; cargarReportes(); })),
                  if (filtroFechaFin != null)
                    _chipFiltro(
                        'Hasta: ${_formatearFecha(filtroFechaFin!.toIso8601String())}',
                            () => setState(() { filtroFechaFin = null; cargarReportes(); })),
                ],
              ),
            ),

          // ── Contador ──────────────────────────────────────────
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Text(
                  '${_reportesFiltrados.length} reporte(s)',
                  style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // ── Lista ─────────────────────────────────────────────
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _reportesFiltrados.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off,
                      size: 60,
                      color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    _textoBusqueda.isNotEmpty
                        ? 'Sin resultados para "$_textoBusqueda"'
                        : 'No hay reportes con los filtros aplicados',
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: cargarReportes,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _reportesFiltrados.length,
                itemBuilder: (context, index) {
                  final r = _reportesFiltrados[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SupervisorReporteDetallePage(
                                reporte: r,
                                onCambiarEstado: cambiarEstado,
                                onAgregarComentario: agregarComentario,
                              ),
                        ),
                      ).then((_) => cargarReportes()),
                      leading: CircleAvatar(
                        backgroundColor: _colorStatus(r['estado']),
                        radius: 6,
                      ),
                      title: Text(
                        r['folio'] ?? 'Sin folio',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${r['tipoPlaga'] ?? 'Sin tipo'} • ${r['estadoUbicacion']} • ${r['municipio']}\n'
                            '${_formatearFecha(r['fecha'])}',
                      ),
                      isThreeLine: true,
                      trailing: SizedBox(
                        width: 110,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _colorStatus(r['estado']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  r['estado'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18),
                              onSelected: (v) => cambiarEstado(r['id'], v),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'Pendiente',
                                  child: Text('Pendiente'),
                                ),
                                PopupMenuItem(
                                  value: 'En proceso',
                                  child: Text('En proceso'),
                                ),
                                PopupMenuItem(
                                  value: 'Atendido',
                                  child: Text('Atendido'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String label, VoidCallback onEliminar) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onEliminar,
      backgroundColor: Colors.teal.shade50,
      side: BorderSide(color: Colors.teal.shade200),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    ),
  );

  //Cuadros de pendiente, en proceso, atendido

  Widget _statsStatus() {
    final pendientes = _contarStatus('Pendiente');
    final enProceso = _contarStatus('En proceso');
    final atendidos = _contarStatus('Atendido');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          _statusCard(
            titulo: 'Pendiente',
            cantidad: pendientes,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          _statusCard(
            titulo: 'En proceso',
            cantidad: enProceso,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          _statusCard(
            titulo: 'Atendido',
            cantidad: atendidos,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _statusCard({
    required String titulo,
    required int cantidad,
    required Color color,
  }) {
    final seleccionado =
        filtroStatusRapido == titulo;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (filtroStatusRapido == titulo) {
              filtroStatusRapido = null;
            } else {
              filtroStatusRapido = titulo;
            }
          });

          _aplicarFiltrosLocales();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: seleccionado
                ? color.withOpacity(0.15)
                : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionado
                  ? color
                  : color.withOpacity(0.25),
              width: seleccionado ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                cantidad.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SupervisorFiltrosSheet(
        filtroStatus: filtroStatus,
        filtroPlaga: filtroPlaga,
        filtroFechaInicio: filtroFechaInicio,
        filtroFechaFin: filtroFechaFin,
        tiposPlaga: tiposPlaga,
        onAplicar: (status, plaga, fechaInicio, fechaFin) {
          setState(() {
            filtroStatus = status;
            filtroPlaga = plaga;
            filtroFechaInicio = fechaInicio;
            filtroFechaFin = fechaFin;
          });
          Navigator.pop(context);
          cargarReportes();
        },
        onLimpiar: () {
          Navigator.pop(context);
          _limpiarFiltros();
        },
      ),
    );
  }
}

// ─── Detalle del reporte ──────────────────────────────────────────
class SupervisorReporteDetallePage extends StatefulWidget {
  final dynamic reporte;
  final Future<void> Function(int, String) onCambiarEstado;
  final Future<void> Function(int, String) onAgregarComentario;

  const SupervisorReporteDetallePage({
    super.key,
    required this.reporte,
    required this.onCambiarEstado,
    required this.onAgregarComentario,
  });

  @override
  State<SupervisorReporteDetallePage> createState() =>
      _SupervisorReporteDetallePageState();
}

class _SupervisorReporteDetallePageState
    extends State<SupervisorReporteDetallePage> {
  final comentarioCtrl = TextEditingController();

  @override
  void dispose() {
    comentarioCtrl.dispose();
    super.dispose();
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return '-';
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }

  Color _colorStatus(String? s) {
    switch (s) {
      case 'Atendido':   return Colors.green;
      case 'En proceso': return Colors.orange;
      default:           return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r          = widget.reporte;
    final comentarios = List.from(r['comentarios']     ?? []);
    final historial   = List.from(r['historialEstatus'] ?? []);
    final usuario     = r['usuario'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(r['folio'] ?? 'Detalle'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Datos del reporte ────────────────────────────
            _seccion('Información del reporte'),
            _dato('Folio',             r['folio']),
            _dato('Tipo de plaga',     r['tipoPlaga']),
            _dato('Descripción',       r['descripcion']),
            _dato('Municipio',         r['municipio']),
            _dato('Localidad',         r['localidad']),
            _dato('Árboles afectados', '${r['cantidadArboles']}'),
            _dato('Fecha registro',    _formatearFecha(r['fecha'])),
            _dato('Status actual',     r['estado']),

            const SizedBox(height: 8),

            // ── Registrante ──────────────────────────────────
            _seccion('Datos del registrante'),
            _dato('Nombre',   usuario['nombre']),
            _dato('Correo',   usuario['email']),
            _dato('Teléfono', usuario['telefono']),

            const SizedBox(height: 8),

            // ── Imágenes ─────────────────────────────────────────
            if ((r['imagenes'] as List? ?? []).isNotEmpty) ...[
              _seccion('Imágenes (${(r['imagenes'] as List).length})'),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (r['imagenes'] as List).length,
                  itemBuilder: (_, i) {
                    final url = r['imagenes'][i] as String;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          barrierColor: Colors.black,
                          pageBuilder: (_, __, ___) => ImagenVisorPage(
                            imagenes: List<String>.from(r['imagenes']),
                            indiceInicial: i,
                          ),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                      ),
                      child: Hero(
                        tag: 'imagen_$url',
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.teal.shade200, width: 1.5),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
                                  url,
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey, size: 40),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 6, right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.zoom_in,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],



            // ── Cambiar status ───────────────────────────────
            _seccion('Cambiar status'),
            Wrap(
              spacing: 8,
              children: ['Pendiente', 'En proceso', 'Atendido'].map((s) {
                final esActual = r['estado'] == s;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esActual
                        ? _colorStatus(s).withOpacity(0.3)
                        : _colorStatus(s),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: esActual
                      ? null
                      : () async {
                    //  Ventana de confirmación
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Confirmar cambio'),
                        content: Text(
                          '¿Estás seguro de cambiar el status a "$s"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorStatus(s),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text('Sí, cambiar'),
                          ),
                        ],
                      ),
                    );

                    //  Si cancela no hace nada
                    if (confirmar != true) return;
                    //  Cambiar status
                    await widget.onCambiarEstado(r['id'], s);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(s),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── Historial de status ──────────────────────────
            _seccion('Historial de status (${historial.length})'),
            if (historial.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Sin cambios registrados',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            ...historial.map((h) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.history,
                      size: 18, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _chipStatus(h['estadoAnterior'] ?? 'Inicio'),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward,
                                  size: 14, color: Colors.grey),
                            ),
                            _chipStatus(h['estadoNuevo']),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${h['nombreUsuario']} (${h['rolUsuario']})',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _formatearFecha(h['fechaHora']),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 16),

            // ── Comentarios ──────────────────────────────────
            _seccion('Comentarios (${comentarios.length})'),
            if (comentarios.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Sin comentarios aún',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            ...comentarios.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['texto'] ?? '',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${c['nombreUsuario']} (${c['rolUsuario']}) • '
                        '${_formatearFecha(c['fechaHora'])}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 8),

            // ── Nuevo comentario ─────────────────────────────
            TextField(
              controller: comentarioCtrl,
              decoration: const InputDecoration(
                labelText: 'Agregar comentario de seguimiento',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Enviar comentario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (comentarioCtrl.text.trim().isNotEmpty) {
                    await widget.onAgregarComentario(
                        r['id'], comentarioCtrl.text.trim());
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _chipStatus(String? label) {
    Color color;
    switch (label) {
      case 'Atendido':   color = Colors.green;  break;
      case 'En proceso': color = Colors.orange; break;
      case 'Pendiente':  color = Colors.red;    break;
      default:           color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label ?? '-',
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  Widget _seccion(String titulo) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(titulo,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.teal)),
  );

  Widget _dato(String label, String? valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 150,
            child: Text('$label:',
                style:
                const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(valor ?? '-')),
      ],
    ),
  );
}

// ─── Panel de filtros supervisor ──────────────────────────────────
class _SupervisorFiltrosSheet extends StatefulWidget {
  final String? filtroStatus;
  final String? filtroPlaga;
  final DateTime? filtroFechaInicio;
  final DateTime? filtroFechaFin;
  final List<TipoPlaga> tiposPlaga;
  final void Function(String?, String?, DateTime?, DateTime?) onAplicar;
  final VoidCallback onLimpiar;

  const _SupervisorFiltrosSheet({
    required this.filtroStatus,
    required this.filtroPlaga,
    required this.filtroFechaInicio,
    required this.filtroFechaFin,
    required this.tiposPlaga,
    required this.onAplicar,
    required this.onLimpiar,
  });

  @override
  State<_SupervisorFiltrosSheet> createState() =>
      _SupervisorFiltrosSheetState();
}

class _SupervisorFiltrosSheetState extends State<_SupervisorFiltrosSheet> {
  String? status;
  String? plaga;
  DateTime? fechaInicio;
  DateTime? fechaFin;

  @override
  void initState() {
    super.initState();
    status      = widget.filtroStatus;
    plaga       = widget.filtroPlaga;
    fechaInicio = widget.filtroFechaInicio;
    fechaFin    = widget.filtroFechaFin;
  }

  String _formatearFecha(DateTime? dt) {
    if (dt == null) return 'Seleccionar';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? (fechaInicio ?? hoy) : (fechaFin ?? hoy),
      firstDate: DateTime(2020),
      lastDate: hoy,
      helpText: esInicio ? 'Fecha inicio' : 'Fecha fin',
      locale: const Locale('es', 'MX'),
    );
    if (picked != null) {
      setState(() {
        if (esInicio) {
          fechaInicio = picked;
          if (fechaFin != null && fechaFin!.isBefore(fechaInicio!)) {
            fechaFin = null;
          }
        } else {
          fechaFin = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Contenido scrolleable ────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text('Filtros',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Dropdown Status
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: 'Status del reporte',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.flag_outlined,
                          color: Colors.teal),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(
                          value: 'Pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(
                          value: 'En proceso', child: Text('En proceso')),
                      DropdownMenuItem(
                          value: 'Atendido', child: Text('Atendido')),
                    ],
                    onChanged: (v) => setState(() => status = v),
                  ),

                  const SizedBox(height: 12),

                  // Dropdown Tipo de plaga
                  DropdownButtonFormField<String>(
                    value: plaga,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Tipo de plaga',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.bug_report_outlined,
                          color: Colors.teal),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Todas')),
                      ...widget.tiposPlaga.map((t) => DropdownMenuItem(
                          value: t.nombre, child: Text(t.nombre))),
                    ],
                    onChanged: (v) => setState(() => plaga = v),
                  ),

                  const SizedBox(height: 12),

                  // Rango de fechas
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rango de fechas',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _seleccionarFecha(true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: fechaInicio != null
                                        ? Colors.teal.shade50
                                        : Colors.grey.shade100,
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                        color: fechaInicio != null
                                            ? Colors.teal.shade300
                                            : Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text('Desde',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        const Icon(Icons.calendar_today,
                                            size: 14,
                                            color: Colors.teal),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatearFecha(fechaInicio),
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: fechaInicio != null
                                                  ? Colors.black87
                                                  : Colors.grey),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward,
                                  size: 16, color: Colors.grey),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => _seleccionarFecha(false),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: fechaFin != null
                                        ? Colors.teal.shade50
                                        : Colors.grey.shade100,
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                        color: fechaFin != null
                                            ? Colors.teal.shade300
                                            : Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text('Hasta',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        const Icon(Icons.calendar_today,
                                            size: 14,
                                            color: Colors.teal),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatearFecha(fechaFin),
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: fechaFin != null
                                                  ? Colors.black87
                                                  : Colors.grey),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (fechaInicio != null || fechaFin != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() {
                                  fechaInicio = null;
                                  fechaFin = null;
                                }),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Botones fijos en la parte inferior ───────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              // Toma el padding real del sistema + margen extra
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar todo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal, // verde para admin
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: widget.onLimpiar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // verde para admin
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => widget.onAplicar(
                         status, plaga, fechaInicio, fechaFin),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}