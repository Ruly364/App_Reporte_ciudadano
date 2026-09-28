import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:plagas_app/config/api_config.dart';
import 'package:plagas_app/reporte_page.dart';
import 'package:plagas_app/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/offline_service.dart';
import 'reporte_detalle_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MisReportesPage extends StatefulWidget {
  const MisReportesPage({super.key});

  @override
  State<MisReportesPage> createState() => _MisReportesPageState();
}

class _MisReportesPageState extends State<MisReportesPage>
    with SingleTickerProviderStateMixin {
  static const _verde      = Color(0xFF2D6A4F);
  static const _verdeClaro = Color(0xFFF0F4F0);
  String filtroSeleccionado = 'todos';

  late TabController _tabController;
  List<Map<String, dynamic>> pendientes = [];
  List<Map<String, dynamic>> enviados = [];
  bool _cargando  = false;

  /// IDs de reportes que actualmente se están enviando.
  /// Evita dobles pulsaciones y permite mostrar "Enviando...".
  final Set<int> _enviandoIds = <int>{};



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> cargarDatos() async {
    setState(() => _cargando = true);
    await Future.wait([cargarPendientes(), cargarEnviados()]);
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> cargarPendientes() async {
    final data = await OfflineService.obtenerPendientes();
    if (mounted) setState(() {
      pendientes =
      List<Map<String, dynamic>>.from(data);

    });
  }

  Future<void> cargarEnviados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reportes/mis-reportes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        //setState(() => enviados = jsonDecode(response.body));
        final lista = List<Map<String, dynamic>>.from(
          jsonDecode(response.body),
        );

        lista.sort((a, b) {
          final fechaA = DateTime.tryParse(a['fecha'] ?? '') ?? DateTime(2000);
          final fechaB = DateTime.tryParse(b['fecha'] ?? '') ?? DateTime(2000);

          return fechaB.compareTo(fechaA);
        });

        setState(() => enviados = lista);

      }
    } catch (_) {}
  }

  Future<void> enviarUno(
      Map<String, dynamic> reporte,
      ) async {
    final id = reporte['id'] as int;

    // Protección adicional contra doble pulsación.
    if (_enviandoIds.contains(id)) {
      return;
    }

    setState(() {
      _enviandoIds.add(id);
    });

    try {
      final resultado =
      await SyncService.enviarUno(reporte);

      if (!mounted) return;

      _snack(resultado.mensaje);

      if (resultado.enviado) {
        // El reporte ya fue confirmado por el servidor.
        // Recargamos pendientes y enviados.
        await cargarDatos();
      }
    } catch (e) {
      if (!mounted) return;

      _snack(
        'No fue posible enviar el reporte en este momento. '
            'Permanecerá guardado y se intentará nuevamente '
            'cuando haya conexión.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviandoIds.remove(id);
        });
      }
    }
  }

  Future<void> eliminarReporte(int id) async {
    // Confirmación antes de eliminar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar reporte'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este reporte pendiente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await OfflineService.eliminarReporte(id);
      _snack("Reporte eliminado");
      await cargarDatos();
    }
  }

  // ── Estadísticas rápidas ──────────────────────────────────
  Widget _statsRow() {
    final atendidos = enviados
        .where((r) => (r['estado'] ?? '').toLowerCase() == 'atendido')
        .length;

    final enProceso = enviados
        .where((r) => (r['estado'] ?? '').toLowerCase() == 'en proceso')
        .length;


    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Row(
        children: [
          _statChip(
            pendientes.length.toString(),
            'Sin enviar',
            Colors.orange.shade50,
            Colors.orange.shade700,
            'pendientes',
          ),

          const SizedBox(width: 8),

          _statChip(
            enviados.length.toString(),
            'Enviados',
            const Color(0xFFEAF3DE),
            _verde,
            'enviados',
          ),

          const SizedBox(width: 8),

          _statChip(
            enProceso.toString(),
            'En proceso',
            Colors.purple.shade50,
            Colors.purple.shade700,
            'en proceso',
          ),

          const SizedBox(width: 8),

          _statChip(
            atendidos.toString(),
            'Atendidos',
            Colors.blue.shade50,
            Colors.blue.shade700,
            'atendido',
          ),
        ],
      ),
    );
  }

  Widget _statChip(
      String num,
      String label,
      Color bg,
      Color fg,
      String filtro,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            filtroSeleccionado = filtro;
            if (filtro == 'pendientes') {
              _tabController.animateTo(0);
            } else {
              _tabController.animateTo(1);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: filtroSeleccionado == filtro
                ? fg.withOpacity(0.15)
                : bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: fg.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                num,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: fg.withOpacity(.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Badge de estado ────────────────────────────────────────
  Widget _badge(String estado) {
    Color bg; Color fg;
    switch (estado.toLowerCase()) {
      case 'atendido':
        bg = Colors.blue.shade50; fg = Colors.blue.shade700; break;
      case 'en proceso':
        bg = Colors.purple.shade50; fg = Colors.purple.shade700; break;
      case 'pendiente':
        bg = Colors.orange.shade50; fg = Colors.orange.shade700; break;
      default:
        bg = const Color(0xFFEAF3DE); fg = _verde;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(estado,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  // ── Tarjeta de reporte ─────────────────────────────────────
  Widget _reporteCard({
    Map<String, dynamic>? reporte,
    required String tipo,
    required String estado,
    required String folio,
    required double lat,
    required double lng,
    required List<String> imagenes,
    String? descripcion,
    String? estadoUbicacion,
    String? municipio,
    String? localidad,
    int? cantidadArboles,
    String? fecha,
    bool esPendiente = false,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReporteDetallePage(
            reporte: {
              'folio': folio,
              'tipoPlaga': tipo,
              'estado': estado,
              'latitud': lat,
              'longitud': lng,
              'imagenes': imagenes,
              'descripcion': descripcion,
              'estadoUbicacion': estadoUbicacion,
              'municipio': municipio,
              'localidad': localidad,
              'cantidadArboles': cantidadArboles,
              'fecha': fecha,
            },
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Encabezado ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folio,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _verde,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tipo,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _badge(esPendiente ? 'Pendiente' : estado),
                ],
              ),
            ),

            // ── Mapa ─────────────────────────────────────────
            SizedBox(
              height: 130,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lng),
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("reporte"),
                        position: LatLng(lat, lng),
                      )
                    },
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                  ),
                ],
              ),
            ),

            // ── Imágenes ──────────────────────────────────────
            if (imagenes.isNotEmpty)
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  itemCount: imagenes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final img = imagenes[i];
                    Widget w;
                    if (img.startsWith('http')) {
                      w = Image.network(img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image));
                    } else {
                      final f = File(img);
                      w = f.existsSync()
                          ? Image.file(f, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported);
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(width: 64, height: 64, child: w),
                    );
                  },
                ),
              ),

            // ── Metadata ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (estadoUbicacion != null || municipio != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        [estadoUbicacion, municipio, localidad]
                            .where((s) => s != null && s.isNotEmpty)
                            .join(' · '),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ]),
                  if (fecha != null && fecha.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _formatFecha(fecha),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ]),
                ],
              ),
            ),

            // ── Acciones (solo pendientes) ─────────────────────
            if (esPendiente && reporte != null) ...[
              Divider(height: 1, thickness: 0.5, color: Colors.grey[100]),
              IntrinsicHeight(
                child: Row(children: [
                  // Enviar
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final int id = reporte['id'] as int;
                        final bool enviando = _enviandoIds.contains(id);

                        return TextButton.icon(
                          onPressed: enviando
                              ? null
                              : () => enviarUno(reporte),

                          icon: enviando
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(
                            Icons.send_rounded,
                            size: 16,
                          ),

                          label: Text(
                            enviando
                                ? 'Enviando...'
                                : 'Enviar',
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),

                          style: TextButton.styleFrom(
                            foregroundColor: _verde,
                            disabledForegroundColor:
                            Colors.grey.shade500,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            shape:
                            const RoundedRectangleBorder(),
                          ),
                        );
                      },
                    ),
                  ),
                  VerticalDivider(
                      width: 1,
                      thickness: 0.5,
                      color: Colors.grey[100]),
                  // Eliminar
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () =>
                          eliminarReporte(reporte['id']),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 16),
                      label: const Text('Eliminar',
                          style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      const meses = [
        '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${dt.day} ${meses[dt.month]} ${dt.year}';
    } catch (_) {
      return fecha;
    }
  }

  // ── Tab pendientes ─────────────────────────────────────────
  Widget _tabPendientes() {
    if (pendientes.isEmpty) return _emptyState(
      Icons.cloud_upload_outlined,
      'Sin reportes pendientes',
      'Los reportes guardados sin conexión aparecerán aquí',
    );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
      itemCount: pendientes.length,
      itemBuilder: (_, i) {
        final Map<String, dynamic> r =
        Map<String, dynamic>.from(pendientes[i]);
        List<String> imgs = [];
        if (r['imagenes'] != null) {
          imgs = List<String>.from(jsonDecode(r['imagenes']));
        }
        return _reporteCard(
          reporte: r,
          tipo: r['tipoPlaga'] ?? '',
          estado: 'Pendiente',
          folio: r['uuid'] ?? 'SIN FOLIO',
          lat: (r['latitud'] ?? 0).toDouble(),
          lng: (r['longitud'] ?? 0).toDouble(),
          imagenes: imgs,
          descripcion: r['descripcion'],
          estadoUbicacion: r['estado'],
          municipio: r['municipio'],
          localidad: r['localidad'],
          cantidadArboles: r['cantidadArboles'],
          fecha: r['fecha'],
          esPendiente: true,
        );
      },
    );
  }

  // ── Tab enviados ───────────────────────────────────────────
  Widget _tabEnviados() {

    List reportesFiltrados = enviados;

    if (filtroSeleccionado == 'atendido') {
      reportesFiltrados = enviados.where((r) =>
      (r['estado'] ?? '').toLowerCase() == 'atendido').toList();
    }
    else if (filtroSeleccionado == 'en proceso') {
      reportesFiltrados = enviados.where((r) =>
      (r['estado'] ?? '').toLowerCase() == 'en proceso').toList();
    }
    else if (filtroSeleccionado == 'enviados') {
      reportesFiltrados = enviados;
    }


    if (enviados.isEmpty) return _emptyState(
      Icons.assignment_outlined,
      'Sin reportes enviados',
      'Tus reportes enviados aparecerán aquí',
    );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
      itemCount: reportesFiltrados.length,
      itemBuilder: (_, i) {

        final Map<String, dynamic> r =
        Map<String, dynamic>.from(
            reportesFiltrados[i]);

        List<String> imgs = [];
        if (r['imagenes'] != null) {
          imgs = List<String>.from(r['imagenes'] ?? []);
        }
        return _reporteCard(
          tipo: r['tipoPlaga'] ?? '',
          estado: r['estado'] ?? '',
          folio: r['folio'] ?? '',
          lat: (r['latitud'] ?? 0).toDouble(),
          lng: (r['longitud'] ?? 0).toDouble(),
          imagenes: imgs,
          descripcion: r['descripcion'],
          estadoUbicacion: r['estadoUbicacion'],
          municipio: r['municipio'],
          localidad: r['localidad'],
          cantidadArboles: r['cantidadArboles'],
          fecha: r['fecha'],
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String titulo, String subtitulo) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(titulo,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500])),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(subtitulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _verdeClaro,
      appBar: AppBar(
        backgroundColor: _verde,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mis reportes',
            style: TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          // Sincronizar todo
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Sincronizar pendientes',
            onPressed: () async {
              final n = await SyncService.sincronizarPendientes();
              _snack('Enviados: $n');
              await cargarDatos();
            },
          ),
          // Refrescar
          IconButton(
            icon: _cargando
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : cargarDatos,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 2.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: 'Pendientes (${pendientes.length})'),
            Tab(text: 'Enviados (${enviados.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Estadísticas
          _statsRow(),
          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_tabPendientes(), _tabEnviados()],
            ),
          ),
        ],
      ),
    );
  }
}