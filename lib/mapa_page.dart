import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:plagas_app/config/api_config.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final Set<Marker> _marcadores = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    cargarReportes();
  }

  Future<void> cargarReportes() async {
  //final uri = Uri.parse('http://187.218.23.89/PlagasForestalesAPI/api/reportes');//server
  final uri = Uri.parse('${ApiConfig.baseUrl}/reportes');
    

  final response = await http.get(uri);

  print('STATUS: ${response.statusCode}');
  print('BODY: ${response.body}');

  if (response.statusCode == 200) {
    final List datos = jsonDecode(response.body);

    final Set<Marker> nuevosMarcadores = {};

    for (var r in datos) {
      final lat = r['latitud'];
      final lng = r['longitud'];

      if (lat == null || lng == null) continue;

      nuevosMarcadores.add(
        Marker(
          markerId: MarkerId('reporte_${r['id']}'),
          position: LatLng(lat.toDouble(), lng.toDouble()),
          infoWindow: InfoWindow(
            title: r['tipoPlaga'],
            snippet: r['descripcion'],
          ),
        ),
      );
    }

    setState(() {
      _marcadores
        ..clear()
        ..addAll(nuevosMarcadores);
    });

    if (_marcadores.isNotEmpty) {
  final first = _marcadores.first.position;
  _mapController?.animateCamera(
    CameraUpdate.newLatLngZoom(first, 14),
  );
}


    print('Marcadores creados: ${_marcadores.length}');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de reportes')),
      body: GoogleMap(
         onMapCreated: (controller) {
        _mapController = controller; 
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(19.4326, -99.1332),
          zoom: 6,
        ),
        markers: _marcadores,
        myLocationEnabled: true,
      ),
    );
  }
}