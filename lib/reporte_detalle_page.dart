import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReporteDetallePage extends StatefulWidget {
  final Map<String, dynamic> reporte;

  const ReporteDetallePage({super.key, required this.reporte});

  @override
  State<ReporteDetallePage> createState() => _ReporteDetallePageState();
}

class _ReporteDetallePageState extends State<ReporteDetallePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  GoogleMapController? _mapController;
  MapType _mapType = MapType.normal;
  bool _mapExpanded = false;

  // Paleta forestal
  static const Color _forestGreen = Color(0xFF2D6A4F);
  static const Color _leafGreen = Color(0xFF40916C);
  static const Color _mintGreen = Color(0xFFB7E4C7);
  static const Color _earthBrown = Color(0xFF6B4226);
  static const Color _warmCream = Color(0xFFF9F5F0);
  static const Color _alertAmber = Color(0xFFE9A838);
  static const Color _cardWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  String _estadoColor(String? estado) {
    switch ((estado ?? '').toLowerCase()) {
      case 'pendiente':
        return 'amber';
      case 'en proceso':
        return 'blue';
      case 'resuelto':
        return 'green';
      default:
        return 'grey';
    }
  }

  Color _estadoBadgeColor(String? estado) {
    switch ((estado ?? '').toLowerCase()) {
      case 'pendiente':
        return _alertAmber;
      case 'en proceso':
        return const Color(0xFF2196F3);
      case 'resuelto':
        return _leafGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = List<String>.from(widget.reporte['imagenes'] ?? []);
    final lat = (widget.reporte['latitud'] as num?)?.toDouble() ?? 0.0;
    final lng = (widget.reporte['longitud'] as num?)?.toDouble() ?? 0.0;
    final target = LatLng(lat, lng);

    return Scaffold(
      backgroundColor: _warmCream,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── SliverAppBar con gradiente ──
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: _forestGreen,
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Folio ${widget.reporte['folio'] ?? 'SIN FOLIO'}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _EstadoBadge(
                      label: widget.reporte['estado'] ?? 'Sin estado',
                      color: _estadoBadgeColor(widget.reporte['estado']),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B4332), Color(0xFF40916C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -20,
                        child: Opacity(
                          opacity: 0.08,
                          child: Icon(Icons.forest,
                              size: 200, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Contenido ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // DATOS GENERALES
                  _SectionCard(
                    icon: Icons.bug_report_outlined,
                    iconColor: _earthBrown,
                    title: 'Datos Generales',
                    children: [
                      _InfoRow(
                        label: 'Tipo de plaga',
                        value: widget.reporte['tipoPlaga'] ?? '—',
                        icon: Icons.pest_control,
                      ),
                      _InfoRow(
                        label: 'Descripción',
                        value: widget.reporte['descripcion'] ?? '—',
                        icon: Icons.description_outlined,
                        multiline: true,
                      ),
                      _InfoRow(
                        label: 'Fecha',
                        value: widget.reporte['fecha'] ?? '—',
                        icon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // DATOS FORESTALES
                  _SectionCard(
                    icon: Icons.park_outlined,
                    iconColor: _forestGreen,
                    title: 'Datos Forestales',
                    children: [
                      _InfoRow(
                        label: 'Árboles afectados',
                        value:
                        '${widget.reporte['cantidadArboles'] ?? '—'} árboles',
                        icon: Icons.forest_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // UBICACIÓN
                  _SectionCard(
                    icon: Icons.place_outlined,
                    iconColor: const Color(0xFFD62828),
                    title: 'Ubicación',
                    children: [
                      _InfoRow(
                        label: 'Estado',
                        value: widget.reporte['estadoUbicacion'] ?? '—',
                        icon: Icons.map_outlined,
                      ),
                      _InfoRow(
                        label: 'Municipio',
                        value: widget.reporte['municipio'] ?? '—',
                        icon: Icons.location_city_outlined,
                      ),
                      _InfoRow(
                        label: 'Localidad',
                        value: widget.reporte['localidad'] ?? '—',
                        icon: Icons.holiday_village_outlined,
                      ),
                      const Divider(height: 20, thickness: 0.5),
                      // Latitud y Longitud
                      Row(
                        children: [
                          Expanded(
                            child: _CoordChip(
                              label: 'Latitud',
                              value: lat.toStringAsFixed(6),
                              icon: Icons.swap_vert,
                              color: _forestGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CoordChip(
                              label: 'Longitud',
                              value: lng.toStringAsFixed(6),
                              icon: Icons.swap_horiz,
                              color: _leafGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // MAPA INTERACTIVO
                  _MapCard(
                    target: target,
                    folio: widget.reporte['folio'] ?? '',
                    mapType: _mapType,
                    expanded: _mapExpanded,
                    onMapCreated: (ctrl) => _mapController = ctrl,
                    onToggleExpand: () =>
                        setState(() => _mapExpanded = !_mapExpanded),
                    onToggleMapType: () => setState(() {
                      _mapType = _mapType == MapType.normal
                          ? MapType.satellite
                          : MapType.normal;
                    }),
                    onCenter: () => _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(target, 16),
                    ),
                    forestGreen: _forestGreen,
                    leafGreen: _leafGreen,
                    mintGreen: _mintGreen,
                  ),

                  // IMÁGENES
                  if (imagenes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _ImagenesSection(
                      imagenes: imagenes,
                      forestGreen: _forestGreen,
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _EstadoBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool multiline;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
        multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
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

class _CoordChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CoordChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copiada'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E)),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final LatLng target;
  final String folio;
  final MapType mapType;
  final bool expanded;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleMapType;
  final VoidCallback onCenter;
  final Color forestGreen;
  final Color leafGreen;
  final Color mintGreen;

  const _MapCard({
    required this.target,
    required this.folio,
    required this.mapType,
    required this.expanded,
    required this.onMapCreated,
    required this.onToggleExpand,
    required this.onToggleMapType,
    required this.onCenter,
    required this.forestGreen,
    required this.leafGreen,
    required this.mintGreen,
  });

  @override
  Widget build(BuildContext context) {
    final mapHeight = expanded ? 450.0 : 280.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del mapa
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD62828).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_outlined,
                      color: Color(0xFFD62828), size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Ubicación en Mapa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                // Botón tipo satélite/normal
                _MapIconBtn(
                  icon: mapType == MapType.normal
                      ? Icons.satellite_alt
                      : Icons.map,
                  tooltip: mapType == MapType.normal ? 'Satélite' : 'Normal',
                  onTap: onToggleMapType,
                  color: forestGreen,
                ),
                // Botón centrar
                _MapIconBtn(
                  icon: Icons.my_location,
                  tooltip: 'Centrar',
                  onTap: onCenter,
                  color: forestGreen,
                ),
                // Botón expandir
                _MapIconBtn(
                  icon: expanded ? Icons.fullscreen_exit : Icons.fullscreen,
                  tooltip: expanded ? 'Contraer' : 'Expandir',
                  onTap: onToggleExpand,
                  color: forestGreen,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),

          // Mapa
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: mapHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: target,
                      zoom: 16,
                    ),
                    mapType: mapType,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    onMapCreated: onMapCreated,
                    markers: {
                      Marker(
                        markerId: const MarkerId("reporte"),
                        position: target,
                        infoWindow: InfoWindow(
                          title: 'Reporte $folio',
                          snippet:
                          '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}',
                        ),
                      ),
                    },
                  ),
                  // Overlay con coordenadas
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.gps_fixed,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 5),
                          Text(
                            '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _MapIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _ImagenesSection extends StatelessWidget {
  final List<String> imagenes;
  final Color forestGreen;

  const _ImagenesSection({
    required this.imagenes,
    required this.forestGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: forestGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                  Icon(Icons.photo_library_outlined, color: forestGreen, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Imágenes (${imagenes.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: imagenes.length,
              itemBuilder: (ctx, i) {
                return _ImageTile(
                  imgPath: imagenes[i],
                  index: i,
                  allImages: imagenes,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String imgPath;
  final int index;
  final List<String> allImages;

  const _ImageTile({
    required this.imgPath,
    required this.index,
    required this.allImages,
  });

  Widget _buildImage() {
    if (imgPath.startsWith('http')) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image),
      );
    }
    final file = File(imgPath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return _placeholder(Icons.image_not_supported);
  }

  Widget _placeholder(IconData icon) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[400], size: 28),
          const SizedBox(height: 4),
          Text('No disponible',
              style: TextStyle(fontSize: 9, color: Colors.grey[400])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageViewerPage(
          images: allImages,
          initialIndex: index,
        ),
      ),
    );
  }
}

// Visor de imágenes a pantalla completa con PageView
class _ImageViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageViewerPage({required this.images, required this.initialIndex});

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 60)));
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.contain);
    }
    return const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white54, size: 60));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.images.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(child: _buildImage(widget.images[i])),
        ),
      ),
    );
  }
}