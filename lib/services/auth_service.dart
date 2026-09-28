import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:plagas_app/config/api_config.dart';

class AuthService {
  static const _tiempoMaximo = Duration(seconds: 15);

  static Future<http.Response> _postJson(
    String ruta,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$ruta'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_tiempoMaximo);

      // Los portales cautivos de operadores/devices redirigen la petición a
      // HTML; eso no es una respuesta de la API y se comunica como sin red.
      final tipoContenido = response.headers['content-type']?.toLowerCase() ?? '';
      final cuerpo = response.body.trimLeft().toLowerCase();
      if ((response.statusCode >= 300 && response.statusCode < 400) ||
          (response.statusCode >= 200 &&
              response.statusCode < 300 &&
              (tipoContenido.contains('text/html') ||
                  cuerpo.startsWith('<html') ||
                  cuerpo.startsWith('<!doctype html'))) ||
          cuerpo.contains('odatos.telcel.com') ||
          cuerpo.contains('network-auth.com') ||
          cuerpo.contains('captive portal') ||
          (cuerpo.contains('continue_url=') && cuerpo.contains('redirected'))) {
        throw const SinConexionRedException();
      }
      return response;
    } on SocketException {
      throw const SinConexionRedException();
    } on http.ClientException {
      throw const SinConexionRedException();
    } on TimeoutException {
      throw const SinConexionRedException();
    }
  }

  static Future<AuthResult> solicitarRecuperacion({
    required String identificador,
    required String canal,
  }) async {
    final response = await _postJson(
      '/auth/password-reset/request',
      {'identificador': identificador, 'canal': canal},
    );
    return AuthResult.fromResponse(response);
  }

  static Future<AuthResult> restablecerContrasena({
    required String identificador,
    required String codigo,
    required String nuevaContrasena,
  }) async {
    final response = await _postJson(
      '/auth/password-reset/confirm',
      {
        'identificador': identificador,
        'codigo': codigo,
        'nuevaContrasena': nuevaContrasena,
      },
    );
    return AuthResult.fromResponse(response);
  }

  /// LOGIN con correo O teléfono
  static Future<Map<String, dynamic>?> login({
    String? email,
    String? telefono,
    required String password,
  }) async {

    // ✅ Construimos el body correctamente
    final Map<String, dynamic> body = {
      'password': password,
    };

    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    if (telefono != null && telefono.isNotEmpty) {
      body['telefono'] = telefono;
    }

    final response = await _postJson('/auth/login', body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data;
    }
    if (response.statusCode >= 500) {
      throw const ServidorNoDisponibleException();
    }
    return null;
  }

  /// REGISTER con correo, teléfono o ambos
  static Future<String> register(
      String nombre,
      String? email,
      String? telefono,
      String password,
      int edad,
      String genero,
      String estado,
      String municipio,
      bool esEtnia,
      String etnia,
      ) async {

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'password': password,
        'edad': edad,
        'genero': genero,
        'estado': estado,
        'municipio': municipio,
        'esEtnia': esEtnia,
        'etnia': esEtnia ? etnia : null,
      }),
    );

    if (response.statusCode == 200) return "OK";
    return response.body;
  }
}

class SinConexionRedException implements Exception {
  const SinConexionRedException();
}

class ServidorNoDisponibleException implements Exception {
  const ServidorNoDisponibleException();
}

class AuthResult {
  const AuthResult({required this.exito, required this.mensaje});

  final bool exito;
  final String mensaje;

  factory AuthResult.fromResponse(http.Response response) {
    if (response.statusCode >= 500) {
      return const AuthResult(
        exito: false,
        mensaje: 'No fue posible comunicarse con el servidor. Intenta más tarde.',
      );
    }
    String mensaje = 'No fue posible completar la solicitud.';
    try {
      final body = jsonDecode(response.body);
      mensaje = body is Map<String, dynamic>
          ? (body['mensaje']?.toString() ?? mensaje)
          : response.body;
    } catch (_) {
      if (response.body.isNotEmpty) mensaje = response.body;
    }
    return AuthResult(exito: response.statusCode >= 200 && response.statusCode < 300, mensaje: mensaje);
  }
}
