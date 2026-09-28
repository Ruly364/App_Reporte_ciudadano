import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'home_page.dart';
import 'admin_page.dart';
import 'register_page.dart';
import 'password_reset_page.dart';
import 'manual_viewer_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final loginCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool _verContrasena = false;
  bool _cargando = false;

  // ─────────────────────────────────────────────
  // ABRIR MANUAL
  // ─────────────────────────────────────────────

  void _abrirManual() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) {
        return const ManualViewerPage();
      },
    );
  }

  @override
  void dispose() {
    loginCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo gris/verdoso claro
      backgroundColor: const Color(0xFFEBEFEA),

      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              // ─────────────────────────────────────────
              // IMAGEN SUPERIOR
              // ─────────────────────────────────────────

              const SizedBox(height: 10),

              Container(
                height: 180,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),

                  child: Image.asset(
                    'assets/images/bosquedescortezador.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─────────────────────────────────────────
              // TÍTULO
              // ─────────────────────────────────────────

              const Text(
                'Bienvenido',

                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3020),
                ),

                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              Text(
                'Inicia sesión para continuar',

                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),

                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ─────────────────────────────────────────
              // CORREO / TELÉFONO
              // ─────────────────────────────────────────

              TextField(
                controller: loginCtrl,

                keyboardType: TextInputType.emailAddress,

                decoration: InputDecoration(
                  hintText: 'Correo o teléfono',

                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: Colors.grey,
                  ),

                  filled: true,

                  fillColor: const Color(0xFFF5F7F5),

                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),

                    borderSide: const BorderSide(
                      color: Colors.black12,
                      width: 0.8,
                    ),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),

                    borderSide: const BorderSide(
                      color: Colors.black12,
                      width: 0.8,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),

                    borderSide: const BorderSide(
                      color: Color(0xFF2D6A4F),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ─────────────────────────────────────────
              // CONTRASEÑA
              // ─────────────────────────────────────────

              TextField(
                controller: passCtrl,

                obscureText: !_verContrasena,

                decoration: InputDecoration(
                  hintText: 'Contraseña',

                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.grey,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _verContrasena
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),

                    onPressed: () {
                      setState(() {
                        _verContrasena = !_verContrasena;
                      });
                    },
                  ),

                  filled: true,

                  fillColor: const Color(0xFFF5F7F5),

                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),

                    borderSide: const BorderSide(
                      color: Colors.black12,
                      width: 0.8,
                    ),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),

                    borderSide: const BorderSide(
                      color: Colors.black12,
                      width: 0.8,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),

                    borderSide: const BorderSide(
                      color: Color(0xFF2D6A4F),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─────────────────────────────────────────
              // BOTÓN INICIAR SESIÓN
              // ─────────────────────────────────────────

              SizedBox(
                height: 50,

                child: ElevatedButton(
                  onPressed: _cargando
                      ? null
                      : _iniciarSesion,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4632),

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),

                    elevation: 0,
                  ),

                  child: _cargando
                      ? const SizedBox(
                    height: 20,
                    width: 20,

                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )

                      : const Text(
                    'Iniciar sesión',

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ─────────────────────────────────────────
              // RECUPERAR CONTRASEÑA
              // ─────────────────────────────────────────

              TextButton(
                onPressed: () => Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const PasswordResetPage(),
                  ),
                ),

                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E4632),
                ),

                child: const Text(
                  '¿Olvidaste tu contraseña?',
                ),
              ),

              // ─────────────────────────────────────────
              // REGISTRO
              // ─────────────────────────────────────────

              TextButton(
                onPressed: () => Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                ),

                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E4632),
                ),

                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),

                    children: [
                      TextSpan(
                        text: '¿No tienes cuenta? ',

                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF1E4632),
                        ),
                      ),

                      TextSpan(
                        text: 'Regístrate',

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E4632),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─────────────────────────────────────────
              // SEPARADOR DE AYUDA
              // ─────────────────────────────────────────

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey.withOpacity(0.35),
                      thickness: 0.6,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),

                    child: Text(
                      'Ayuda',

                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  Expanded(
                    child: Divider(
                      color: Colors.grey.withOpacity(0.35),
                      thickness: 0.6,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ─────────────────────────────────────────
              // MANUAL DE INSTALACIÓN Y USO
              // ─────────────────────────────────────────

              TextButton.icon(
                onPressed: _abrirManual,

                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E4632),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),

                icon: const Icon(
                  Icons.menu_book,
                  size: 23,
                ),

                label: const Text(
                  'Ayuda',

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // INICIAR SESIÓN
  // ─────────────────────────────────────────────

  Future<void> _iniciarSesion() async {
    if (loginCtrl.text.trim().isEmpty ||
        passCtrl.text.trim().isEmpty) {

      _mostrarSnack(
        'Correo/teléfono y contraseña son obligatorios',
      );

      return;
    }

    setState(() => _cargando = true);

    try {
      final prefs =
      await SharedPreferences.getInstance();

      final tieneSesion =
          prefs.getBool('sesionActiva') ?? false;

      final connectivity =
      await Connectivity().checkConnectivity();

      final sinInternet =
          connectivity == ConnectivityResult.none;

      if (sinInternet) {

        if (tieneSesion) {

          _mostrarSnack(
            'Modo sin conexión',
          );

          _navegar(
            prefs.getString('rol'),
          );

        } else {

          _mostrarSnack(
            'En este momento no tienes conexión de red',
          );
        }

        return;
      }

      final esCorreo =
      loginCtrl.text.contains('@');

      final result =
      await AuthService.login(
        email: esCorreo
            ? loginCtrl.text.trim()
            : null,

        telefono: esCorreo
            ? null
            : loginCtrl.text.trim(),

        password: passCtrl.text,
      );

      if (result != null) {

        await prefs.setBool(
          'sesionActiva',
          true,
        );

        await prefs.setString(
          'token',
          result['token'],
        );

        await prefs.setString(
          'rol',
          result['rol'] ?? '',
        );

        await prefs.setString(
          'nombre',
          result['nombre'] ?? '',
        );

        _navegar(
          result['rol'],
        );

      } else {

        _mostrarSnack(
          'Credenciales inválidas',
        );
      }

    } on SinConexionRedException {

      _mostrarSnack(
        'En este momento no tienes conexión de red',
      );

    } on ServidorNoDisponibleException {

      _mostrarSnack(
        'No fue posible comunicarse con el servidor. Intenta más tarde.',
      );

    } finally {

      if (mounted) {
        setState(
              () => _cargando = false,
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // NAVEGACIÓN
  // ─────────────────────────────────────────────

  void _navegar(String? rol) {
    if (!mounted) return;

    // Todos van a HomePage,
    // que muestra el botón de panel según el rol.

    Navigator.pushReplacement(
      context,

      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SNACKBAR
  // ─────────────────────────────────────────────

  void _mostrarSnack(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }
}