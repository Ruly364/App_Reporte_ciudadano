import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'mapa_page.dart';
import 'reporte_page.dart';
import 'admin_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    verificarSesion();
  }

  Future<void> verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final rol = prefs.getString('rol');

    await Future.delayed(const Duration(seconds: 1));

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    } else {
      if (rol == 'Administrador') {
        Navigator.pushReplacement(
          context,
          //MaterialPageRoute(builder: (_) => const MapaPage()),
          MaterialPageRoute(builder: (_) => const AdminPage()),

        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReportePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}