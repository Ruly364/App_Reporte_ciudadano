import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plagas_app/services/location_service.dart';
import 'models/tipo_plaga.dart';
import 'services/catalogo_service.dart';
import 'services/catalogo_maestro_service.dart';
import 'services/offline_service.dart';
import 'services/sync_service.dart';
import '../utils/image_helper.dart';
import 'config/api_config.dart';
import 'package:path_provider/path_provider.dart';


class ReportePage extends StatefulWidget {
  final Map? reporte;
  const ReportePage({super.key, this.reporte});

  @override
  State<ReportePage> createState() => _ReportePageState();
}

class _ReportePageState extends State<ReportePage> {

  //======================================================
// VARIABLES
//======================================================

  static const _verde      = Color(0xFF2D6A4F);
  static const _verdeClaro = Color(0xFFF0F4F0);

  bool enviando          = false;

  bool cargandoUbicacion = true;

  double? _latitud;
  double? _longitud;
  double? _precisionGps;
  String _mensajeUbicacion =
      "Obteniendo ubicación...";

  LatLng? _posicionSeleccionada;

  GoogleMapController? _mapController;

  final ScrollController _scrollController = ScrollController();

  MapType _tipoMapa   = MapType.normal;

  bool    _mapaExpandido = false;

  //Catalogos

  String? estadoSeleccionado;

  String? municipioSeleccionado;

  String? localidadSeleccionada;

  List<String> estados     = [];

  List<String> municipios  = [];

  List<String> localidades = [];

  List<TipoPlaga> tiposPlaga    = [];


  TipoPlaga?      tipoSeleccionado;

  //Formulario
  final descripcionCtrl = TextEditingController();

  final arbolesCtrl     = TextEditingController();

  final otroCtrl        = TextEditingController();

  //Imagenes

  final ImagePicker _picker = ImagePicker();

  List<XFile> imagenes = [];

  List<String> rutasImagenes = [];


  bool mostrarOtro   = false;







  // ── Decoraciones ────────────────────────────────────────────
  InputDecoration _decoCard(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _verde, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      );

  InputDecoration _dropDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
    filled: true,
    fillColor: Colors.white,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    contentPadding:
    const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
  );

  // ── Tarjeta agrupadora ──────────────────────────────────────
  Widget _fieldCard(List<Widget> fields) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.black12, width: 0.5),
    ),
    margin: const EdgeInsets.only(bottom: 10),
    child: Column(
      children: fields.asMap().entries.map((e) {
        final isLast = e.key == fields.length - 1;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: e.value,
          ),
          if (!isLast)
            Divider(height: 1, thickness: 0.5, color: Colors.grey[100]),
        ]);
      }).toList(),
    ),
  );

  // ── Etiqueta de sección ─────────────────────────────────────
  Widget _sectionLabel(String texto) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: Colors.grey[500],
      ),
    ),
  );

  Widget _botonMapa({
    required IconData icono,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icono, size: 18, color: _verde),
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      obtenerUbicacion();
      cargarTiposPlaga();
      cargarCatalogoGeografico();
    });
  }



  @override
  void dispose() {

    _scrollController.dispose();

    descripcionCtrl.dispose();

    arbolesCtrl.dispose();

    otroCtrl.dispose();

    _mapController?.dispose();

    super.dispose();

  }


  void _mostrarSnackBar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }



  Future<void> obtenerUbicacion() async {
    if (!mounted) return;

    setState(() {
      cargandoUbicacion = true;
      _mensajeUbicacion = "Obteniendo ubicación precisa...";
    });

    try {
      final posicion = await LocationService.current();

      if (posicion == null) {
        if (!mounted) return;

        setState(() {
          cargandoUbicacion = false;
          _mensajeUbicacion =
          "No se pudo obtener una ubicación GPS precisa.";
        });

        _mostrarSnackBar(
          "GPS no disponible. Puedes continuar capturando "
              "y volver a intentar la ubicación.",
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
        _precisionGps = posicion.accuracy;

        _posicionSeleccionada = LatLng(
          posicion.latitude,
          posicion.longitude,
        );

        cargandoUbicacion = false;

        _mensajeUbicacion =
        "Ubicación GPS · precisión ${posicion.accuracy.toStringAsFixed(1)} m";
      });

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            _posicionSeleccionada!,
          ),
        );
      }

      await _autocompletarUbicacionDesdeGps();

    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoUbicacion = false;
        _mensajeUbicacion =
        "No se pudo obtener la ubicación GPS.";
      });

      debugPrint(
        'Error al obtener ubicación GPS: $e',
      );
    }
  }

  Future<void> tomarFoto() async {
    if (imagenes.length >= 3) {
      _mostrarSnackBar("Máximo 3 fotos");
      return;
    }
    final foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      final ruta = await guardarImagenLocal(File(foto.path));
      if (mounted) {
        setState(() {
          imagenes.add(foto);
          rutasImagenes.add(ruta);
        });
      }
    }
  }

  Future<void> tomarFotoEnSlot(int indice) async {
    final foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto == null) return;

    final ruta = await guardarImagenLocal(File(foto.path));

    if (!mounted) return;
    setState(() {
      if (indice < imagenes.length) {
        imagenes[indice]     = foto;
        rutasImagenes[indice] = ruta;
      } else {
        imagenes.add(foto);
        rutasImagenes.add(ruta);
      }
    });
  }

  Future<void> cargarTiposPlaga() async {


    try {

      //---------------------------------------------------
      // Si hay Internet, actualizamos el catálogo
      //---------------------------------------------------

      final actualizar =
      await OfflineService.necesitaActualizarCatalogo();

      if (actualizar) {

        try {

          final catalogo =
          await CatalogoService.obtenerTiposPlaga();

          if (catalogo.isNotEmpty) {

            await OfflineService.guardarCatalogo(catalogo);

          }

        } catch (_) {}

      }

    } catch (e) {

      debugPrint(
        "No fue posible actualizar el catálogo: $e",
      );

    }

    //---------------------------------------------------
    // Siempre leer desde SQLite
    //---------------------------------------------------

    final datos =
    await OfflineService.obtenerCatalogo();

    if (!mounted) return;

    setState(() {

      tiposPlaga = datos.map((e) {

        return TipoPlaga(

          id: e["id"] as int,

          nombre: e["nombre"] as String,

        );

      }).toList();

    });

    //---------------------------------------------------
    // Si no existe catálogo avisar al usuario
    //---------------------------------------------------

    if (tiposPlaga.isEmpty) {

      _mostrarSnackBar(

        "No existe un catálogo local. Conéctate a Internet una vez para descargarlo.",

      );

    }
  }

  Future<void> cargarCatalogoGeografico() async {
    try {
      final datos = await CatalogoMaestroService.obtenerEstados();
      if (!mounted) return;
      setState(() => estados = datos);
    } catch (e) {
      debugPrint('No fue posible abrir el catálogo maestro: $e');
      _mostrarSnackBar('No fue posible cargar el catálogo geográfico local.');
    }
  }

  Future<void> _autocompletarUbicacionDesdeGps() async {
    if (_latitud == null || _longitud == null) return;
    try {
      final ubicacion = await CatalogoMaestroService.resolverCoordenadas(
        latitud: _latitud!,
        longitud: _longitud!,
      );
      if (!mounted || ubicacion == null) return;

      final municipiosCatalogo =
      await CatalogoMaestroService.obtenerMunicipios(ubicacion.estado);
      final localidadesCatalogo =
      await CatalogoMaestroService.obtenerLocalidades(
        ubicacion.estado,
        ubicacion.municipio,
      );
      if (!mounted) return;
      setState(() {
        estadoSeleccionado = ubicacion.estado;
        municipios = ['Ninguno', ...municipiosCatalogo];
        municipioSeleccionado = ubicacion.municipio;
        localidades = ['Ninguno', ...localidadesCatalogo];
        localidadSeleccionada = ubicacion.localidad;
        _mensajeUbicacion =
        'Ubicación obtenida · ${ubicacion.confianza} (${ubicacion.distanciaMetros.round()} m)';
      });
    } catch (e) {
      debugPrint('No fue posible resolver ubicación local: $e');
    }
  }

  Future<void> _seleccionarEstado(String? valor) async {
    if (valor == null) return;
    final datos = await CatalogoMaestroService.obtenerMunicipios(valor);
    if (!mounted) return;
    setState(() {
      estadoSeleccionado = valor;
      municipios = ['Ninguno', ...datos];
      municipioSeleccionado = 'Ninguno';
      localidadSeleccionada = 'Ninguno';
      localidades = ['Ninguno'];
    });
  }

  Future<void> _seleccionarMunicipio(String? valor) async {
    if (valor == null || estadoSeleccionado == null) return;
    if (valor == 'Ninguno') {
      setState(() {
        municipioSeleccionado = valor;
        localidades = ['Ninguno'];
        localidadSeleccionada = 'Ninguno';
      });
      return;
    }
    final datos = await CatalogoMaestroService.obtenerLocalidades(
      estadoSeleccionado!,
      valor,
    );
    if (!mounted) return;
    setState(() {
      municipioSeleccionado = valor;
      localidades = ['Ninguno', ...datos];
      localidadSeleccionada = 'Ninguno';
    });
  }

  Future<void> mostrarExito(String folio) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (_, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF3DE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: _verde, size: 44),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Reporte enviado!',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu folio de seguimiento es:',
                style:
                TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _verdeClaro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  folio,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _verde,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> mostrarGuardadoLocal() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.cloud_off_rounded, color: _verde, size: 40),
        title: const Text('Reporte guardado localmente'),
        content: const Text(
          'No hay conexión en este momento. Se enviará automáticamente cuando haya Internet.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: _verde),
            child: const Text('Ir al inicio'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> enviarReporte() async {

    if (enviando) return;

    if (estadoSeleccionado == null ||
        municipioSeleccionado == null ||
        localidadSeleccionada == null ||
        tipoSeleccionado == null) {

      _mostrarSnackBar("Completa todos los campos");
      return;
    }

    if (imagenes.length < 3) {

      _mostrarSnackBar("Debes capturar 3 fotografías");
      return;

    }

    if (descripcionCtrl.text.trim().isEmpty) {

      _mostrarSnackBar("Captura la descripción");
      return;

    }

    if (arbolesCtrl.text.trim().isEmpty) {

      _mostrarSnackBar("Ingrese cantidad de árboles afectados");
      return;

    }

    if (_latitud == null || _longitud == null) {

      _mostrarSnackBar("No fue posible obtener la ubicación.");
      return;

    }

    if (mounted) {
      setState(() => enviando = true);
    }

    try {

      final reporte = {

        "tipoPlaga": mostrarOtro
            ? (otroCtrl.text.trim().isEmpty
            ? "No especificado"
            : otroCtrl.text.trim())
            : tipoSeleccionado!.nombre,

        "descripcion": descripcionCtrl.text.trim(),

        "latitud": _latitud,

        "longitud": _longitud,

        "estado": estadoSeleccionado,

        "municipio": municipioSeleccionado,

        "localidad": localidadSeleccionada,

        "cantidadArboles":
        int.tryParse(arbolesCtrl.text) ?? 0,

        "imagenes": rutasImagenes,

        "fecha":
        DateTime.now().toIso8601String(),

      };

      //----------------------------------------------------
      // SIEMPRE guardar primero en SQLite
      //----------------------------------------------------

      final idLocal =
      await OfflineService.guardarReporte(reporte);

      debugPrint("Reporte almacenado localmente: $idLocal");

      //----------------------------------------------------
      // Intentar sincronizar
      //----------------------------------------------------

      final resultado =
      await SyncService.sincronizarReporte(idLocal);

      if (resultado.enviado) {

        await mostrarExito(
            resultado.folio ?? "Sin folio");

      } else {
        await mostrarGuardadoLocal();
        return;

      }

      //----------------------------------------------------
      // Limpiar formulario
      //----------------------------------------------------

      if (mounted) {

        limpiarFormulario();

        if (mounted) {
          setState(() {});
        }

      }

    }

    catch (e) {

      _mostrarSnackBar(

        "El reporte quedó almacenado localmente.\n$e",

      );

    }

    finally {

      if (mounted) {

        setState(() {

          enviando = false;

        });

      }

    }

  }

  void limpiarFormulario() {

    descripcionCtrl.clear();

    arbolesCtrl.clear();

    otroCtrl.clear();

    imagenes.clear();

    rutasImagenes.clear();

    tipoSeleccionado = null;

    estadoSeleccionado = null;

    municipioSeleccionado = null;

    localidadSeleccionada = null;

    municipios.clear();

    localidades.clear();

  }

  // ── Sección de fotos ────────────────────────────────────────
  Widget _seccionFotos() {
    final List<Map<String, dynamic>> slots = [
      {'icon': Icons.panorama_outlined,   'label': 'Foto panorámica'},
      {'icon': Icons.zoom_in_rounded,     'label': 'Detalle del daño'},
      {'icon': Icons.bug_report_outlined, 'label': 'Agente causal'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.camera_alt_outlined, color: _verde, size: 20),
            const SizedBox(width: 8),
            const Text('Captura 3 fotografías',
                style:
                TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ]),
          const SizedBox(height: 10),

          ...slots.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Icon(s['icon'] as IconData,
                  size: 16, color: Colors.grey[500]),
              const SizedBox(width: 7),
              Text(s['label'] as String,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600])),
            ]),
          )),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${imagenes.length} de 3 fotos',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: imagenes.length == 3
                      ? const Color(0xFFEAF3DE)
                      : const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  imagenes.length == 3
                      ? 'Completo ✓'
                      : 'Faltan ${3 - imagenes.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: imagenes.length == 3
                        ? const Color(0xFF27500A)
                        : const Color(0xFFA32D2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: imagenes.length / 3,
              backgroundColor: Colors.grey[200],
              valueColor:
              const AlwaysStoppedAnimation<Color>(_verde),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: List.generate(3, (i) {
              final tomada      = i < imagenes.length;
              final esSiguiente = i == imagenes.length;
              final esTappeable = tomada || esSiguiente;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap:
                        esTappeable ? () => tomarFotoEnSlot(i) : null,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: tomada
                                ? null
                                : esSiguiente
                                ? Colors.green.shade50
                                : Colors.grey[100],
                            border: Border.all(
                              color: tomada
                                  ? _verde
                                  : esSiguiente
                                  ? _verde
                                  : Colors.grey[300]!,
                              width: tomada || esSiguiente ? 1.5 : 1,
                            ),
                            image: tomada
                                ? DecorationImage(
                              image:
                              FileImage(File(imagenes[i].path)),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: tomada
                              ? null
                              : Center(
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  slots[i]['icon'] as IconData,
                                  color: esSiguiente
                                      ? _verde
                                      : Colors.grey[400],
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  slots[i]['label'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: esSiguiente
                                        ? _verde
                                        : Colors.grey[400],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (esSiguiente) ...[
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Toca aquí',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: _verde,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (tomada)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: GestureDetector(
                            onTap: () => tomarFotoEnSlot(i),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ),

                      if (tomada)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              imagenes.removeAt(i);
                              rutasImagenes.removeAt(i);
                            }),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: imagenes.length >= 3 ? null : tomarFoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Tomar fotografía'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _verde,
                side: BorderSide(
                  color: imagenes.length >= 3
                      ? Colors.grey[300]!
                      : _verde,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón enviar (inline al final del formulario) ───────────
  Widget _botonEnviar() => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed: enviando ? null : enviarReporte,
      icon: const Icon(Icons.send_rounded),
      label: const Text(
        'Enviar reporte',
        style:
        TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _verde,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {

    final posicionInicial =
        _posicionSeleccionada ??
            const LatLng(20.6597, -103.3496);

    return Scaffold(
      backgroundColor: _verdeClaro,
      appBar: AppBar(
        backgroundColor: _verde,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nuevo reporte',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      // ── Body: Stack solo para el overlay de carga ────────────
      body: Stack(
        children: [
          Column(
            children: [

              // ── Mapa fijo ──────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _mapaExpandido ? 380 : 220,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: posicionInicial,
                          zoom: 16,
                        ),
                        mapType: _tipoMapa,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        onMapCreated: (c) => _mapController = c,
                        onCameraMove: (pos) {
                          if (_posicionSeleccionada != null) {
                            _latitud = pos.target.latitude;
                            _longitud = pos.target.longitude;
                          }
                        },
                        onCameraIdle: () async {
                          if (!mounted) return;

                          setState(() {});

                          if (_latitud == null || _longitud == null) {
                            return;
                          }

                          await _autocompletarUbicacionDesdeGps();
                        },
                      ),
                    ),

                    // Pin estático centrado
                    const Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.location_pin,
                            size: 44, color: Color(0xFF1E4632)),
                      ),
                    ),

                    // Botones derecha
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Column(
                        children: [
                          _botonMapa(
                            icono: _tipoMapa == MapType.normal
                                ? Icons.satellite_alt
                                : Icons.map_outlined,
                            tooltip: _tipoMapa == MapType.normal
                                ? 'Vista satélite'
                                : 'Vista mapa',
                            onTap: () => setState(() {
                              _tipoMapa = _tipoMapa == MapType.normal
                                  ? MapType.satellite
                                  : MapType.normal;
                            }),
                          ),
                          const SizedBox(height: 8),
                          _botonMapa(
                            icono: Icons.my_location,
                            tooltip: 'Mi ubicación',
                            onTap: () =>
                                _mapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                        target: posicionInicial, zoom: 16),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 8),
                          _botonMapa(
                            icono: _mapaExpandido
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            tooltip: _mapaExpandido
                                ? 'Reducir'
                                : 'Expandir',
                            onTap: () => setState(() =>
                            _mapaExpandido = !_mapaExpandido),
                          ),
                        ],
                      ),
                    ),

                    // Zoom +/-
                    Positioned(
                      right: 10,
                      bottom: 50,
                      child: Column(
                        children: [
                          _botonMapa(
                            icono: Icons.add,
                            tooltip: 'Acercar',
                            onTap: () => _mapController
                                ?.animateCamera(CameraUpdate.zoomIn()),
                          ),
                          const SizedBox(height: 4),
                          _botonMapa(
                            icono: Icons.remove,
                            tooltip: 'Alejar',
                            onTap: () => _mapController
                                ?.animateCamera(CameraUpdate.zoomOut()),
                          ),
                        ],
                      ),
                    ),

                    // Coordenadas
                    // ======================================================
// COORDENADAS GPS
// ======================================================
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black12,
                              width: 0.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                size: 12,
                                color: _verde,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Lat: ${_latitud?.toStringAsFixed(5) ?? '--'}'
                                    '  |  '
                                    'Lng: ${_longitud?.toStringAsFixed(5) ?? '--'}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ======================================================
// INDICADOR DE OBTENCIÓN DE UBICACIÓN GPS
// ======================================================
                    if (cargandoUbicacion || _latitud == null)
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 60,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.black12,
                              width: 0.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _verde,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _mensajeUbicacion,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Formulario scrolleable ─────────────────────
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  // Espacio final para que el botón pueda quedar completamente visible.
                  padding: const EdgeInsets.only(bottom: 36),
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // Ubicación
                          _sectionLabel('Ubicación'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.black12, width: 0.5),
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Column(children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                child:
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: estadoSeleccionado,
                                  decoration: _dropDeco(
                                      'Estado', Icons.map_outlined),
                                  icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey[400]),
                                  items: estados
                                      .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e,
                                          overflow:
                                          TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: _seleccionarEstado,
                                ),
                              ),
                              Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey[100]),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                child:
                                DropdownButtonFormField<String>(
                                  key: ValueKey(estadoSeleccionado),
                                  isExpanded: true,
                                  value: municipioSeleccionado,
                                  decoration: _dropDeco('Municipio',
                                      Icons.location_on_outlined),
                                  icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey[400]),
                                  items: municipios
                                      .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m,
                                          overflow:
                                          TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: _seleccionarMunicipio,
                                ),
                              ),
                              Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey[100]),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                child:
                                DropdownButtonFormField<String>(
                                  key: ValueKey(municipioSeleccionado),
                                  isExpanded: true,
                                  value: localidadSeleccionada,
                                  decoration: _dropDeco('Localidad',
                                      Icons.holiday_village_outlined),
                                  icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey[400]),
                                  items: localidades
                                      .map((l) => DropdownMenuItem(
                                      value: l,
                                      child: Text(l,
                                          overflow:
                                          TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: (v) => setState(
                                          () => localidadSeleccionada = v),
                                ),
                              ),
                            ]),
                          ),


                          // Tipo de plaga
                          _sectionLabel('Tipo de plaga'),
                          _fieldCard([
                            DropdownButtonFormField<TipoPlaga>(
                              value: tipoSeleccionado,
                              decoration: _dropDeco(
                                  'Selecciona el tipo de plaga',
                                  Icons.bug_report_outlined),
                              icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey[400]),
                              items: tiposPlaga
                                  .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.nombre)))
                                  .toList(),
                              onChanged: (v) => setState(() {
                                tipoSeleccionado = v;
                                mostrarOtro = v?.nombre.toLowerCase() ==
                                    "otros";
                              }),
                            ),
                          ]),

                          if (mostrarOtro)
                            _fieldCard([
                              TextField(
                                controller: otroCtrl,
                                decoration: _decoCard(
                                    'Especifica la plaga',
                                    Icons.edit_outlined),
                              ),
                            ]),

                          // Descripción
                          _sectionLabel('Descripción'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.black12, width: 0.5),
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              controller: descripcionCtrl,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText:
                                'Describe los síntomas y condiciones observadas...',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14),
                                prefixIcon: Padding(
                                  padding:
                                  const EdgeInsets.only(bottom: 60),
                                  child: Icon(Icons.notes_outlined,
                                      color: Colors.grey[400], size: 20),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: _verde, width: 1.5),
                                ),
                                contentPadding:
                                const EdgeInsets.all(14),
                              ),
                            ),
                          ),

                          // Árboles
                          _sectionLabel('Árboles afectados'),
                          _fieldCard([
                            TextField(
                              controller: arbolesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _decoCard(
                                  'Cantidad aproximada',
                                  Icons.forest_outlined),
                            ),
                          ]),

                          // Fotografías
                          _sectionLabel('Fotografías'),
                          _seccionFotos(),

                          // El botón aparece como último paso del formulario
                          // cuando el usuario ya llegó a la parte final.
                          // ── Envío del reporte ─────────────────────────────────────
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                            child: Column(
                              children: [
                                Text(
                                  'Cuando hayas terminado, envía tu reporte',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                _botonEnviar(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Overlay de carga ─────────────────────────────────
          if (enviando)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/loading.gif',
                          height: 70),
                      const SizedBox(height: 14),
                      const Text(
                        'Guardando reporte...',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sincronizando información...',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
