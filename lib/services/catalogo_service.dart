import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plagas_app/config/api_config.dart';
import '../models/tipo_plaga.dart';

class CatalogoService {
  static Future<List<TipoPlaga>> obtenerTiposPlaga() async {
    final response = await http.get(
      //Uri.parse('http://10.0.2.2:5036/api/catalogos/tipos-plaga'),
      Uri.parse('${ApiConfig.baseUrl}/catalogos/tipos-plaga'),

    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => TipoPlaga.fromJson(e)).toList();
    }

    return [];
  }
}