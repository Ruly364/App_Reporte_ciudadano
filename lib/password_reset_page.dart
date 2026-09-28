import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'services/auth_service.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  static const _verde = Color(0xFF1E4632);
  final _identificador = TextEditingController();
  final _codigo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _porSms = false;
  bool _enviando = false;
  bool _mostrarCodigo = false;
  bool _verContrasena = false;

  @override
  void dispose() {
    _identificador.dispose();
    _codigo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  void _snack(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _solicitarCodigo() async {
    final identificador = _identificador.text.trim();
    if (identificador.isEmpty) {
      _snack('Ingresa tu correo o número de teléfono.');
      return;
    }
    if (_porSms && identificador.contains('@')) {
      _snack('Para SMS ingresa un número de teléfono.');
      return;
    }
    if (!_porSms && !identificador.contains('@')) {
      _snack('Para correo ingresa una dirección de correo electrónico.');
      return;
    }

    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      _snack('Sin conexión de red');
      return;
    }

    setState(() => _enviando = true);
    try {
      final respuesta = await AuthService.solicitarRecuperacion(
        identificador: identificador,
        canal: _porSms ? 'sms' : 'email',
      );
      if (!mounted) return;
      if (respuesta.exito) {
        setState(() => _mostrarCodigo = true);
        _snack(respuesta.mensaje);
      } else {
        _snack(respuesta.mensaje);
      }
    } on SinConexionRedException {
      _snack('Sin conexión de red');
    } catch (_) {
      _snack('No fue posible conectar con el servicio. Intenta más tarde.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _restablecer() async {
    if (_codigo.text.trim().length != 6) {
      _snack('Ingresa el código de 6 dígitos.');
      return;
    }
    if (_contrasena.text.length < 8) {
      _snack('La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (_contrasena.text != _confirmacion.text) {
      _snack('Las contraseñas no coinciden.');
      return;
    }

    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      _snack('Sin conexión de red');
      return;
    }

    setState(() => _enviando = true);
    try {
      final respuesta = await AuthService.restablecerContrasena(
        identificador: _identificador.text.trim(),
        codigo: _codigo.text.trim(),
        nuevaContrasena: _contrasena.text,
      );
      if (!mounted) return;
      if (respuesta.exito) {
        _snack('Contraseña actualizada. Ahora inicia sesión.');
        Navigator.of(context).pop();
      } else {
        _snack(respuesta.mensaje);
      }
    } on SinConexionRedException {
      _snack('Sin conexión de red');
    } catch (_) {
      _snack('No fue posible actualizar la contraseña.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  InputDecoration _campo(String etiqueta, IconData icono, {Widget? suffix}) =>
      InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFEBEFEA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFEBEFEA),
          title: const Text('Recuperar contraseña'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.lock_reset_rounded, size: 58, color: _verde),
              const SizedBox(height: 16),
              Text(
                _mostrarCodigo
                    ? 'Verifica tu código'
                    : 'Recupera el acceso a tu cuenta',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _mostrarCodigo
                    ? 'Ingresa el código recibido y crea una contraseña nueva.'
                    : 'Te enviaremos un código de validación de un solo uso.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (!_mostrarCodigo) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.email_outlined), label: Text('Correo')),
                    ButtonSegment(value: true, icon: Icon(Icons.sms_outlined), label: Text('SMS')),
                  ],
                  selected: {_porSms},
                  onSelectionChanged: _enviando
                      ? null
                      : (seleccion) => setState(() => _porSms = seleccion.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _identificador,
                  enabled: !_enviando,
                  keyboardType: _porSms ? TextInputType.phone : TextInputType.emailAddress,
                  decoration: _campo(
                    _porSms ? 'Número de teléfono' : 'Correo electrónico',
                    _porSms ? Icons.phone_outlined : Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _enviando ? null : _solicitarCodigo,
                  style: FilledButton.styleFrom(backgroundColor: _verde, minimumSize: const Size.fromHeight(50)),
                  child: _enviando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Enviar código'),
                ),
              ] else ...[
                Text('Código enviado a: ${_identificador.text.trim()}'),
                const SizedBox(height: 16),
                TextField(
                  controller: _codigo,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: _campo('Código de validación', Icons.pin_outlined),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contrasena,
                  obscureText: !_verContrasena,
                  decoration: _campo(
                    'Nueva contraseña',
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      onPressed: () => setState(() => _verContrasena = !_verContrasena),
                      icon: Icon(_verContrasena ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmacion,
                  obscureText: !_verContrasena,
                  decoration: _campo('Confirmar contraseña', Icons.lock_reset_outlined),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _enviando ? null : _restablecer,
                  style: FilledButton.styleFrom(backgroundColor: _verde, minimumSize: const Size.fromHeight(50)),
                  child: _enviando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Actualizar contraseña'),
                ),
                TextButton(
                  onPressed: _enviando ? null : () => setState(() => _mostrarCodigo = false),
                  child: const Text('Solicitar otro código'),
                ),
              ],
            ],
          ),
        ),
      );
}
