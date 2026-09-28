import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'reporte_page.dart';
import 'mis_reportes_page.dart';
import 'admin_page.dart';
import 'supervisor_page.dart';

class HomePage extends StatefulWidget {
const HomePage({super.key});

@override
State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
String nombreUsuario = "";
String rolUsuario = "";
bool cargando = true; // Control de estado seguro

@override
void initState() {
super.initState();
cargarUsuario();
}

Future<void> cargarUsuario() async {
try {
final prefs = await SharedPreferences.getInstance();
setState(() {
nombreUsuario = prefs.getString('nombre') ?? "Usuario";
rolUsuario = prefs.getString('rol') ?? "Usuario";
cargando = false;
});
} catch (e) {
debugPrint("Error cargando SharedPreferences: $e");
setState(() {
cargando = false;
});
}
}

Future<void> _confirmarCerrarSesion() async {
final confirmar = await showDialog<bool>(
context: context,
barrierDismissible: false,
builder: (dialogContext) => AlertDialog(
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
title: const Text('Cerrar sesión'),
content: const Text(
'¿Estás seguro que quieres cerrar sesión?',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('No'),
),
FilledButton(
onPressed: () => Navigator.pop(dialogContext, true),
style: FilledButton.styleFrom(
backgroundColor: Color(0xFF1E4620),
),
child: const Text('Sí'),
),
],
),
);

if (confirmar != true || !mounted) return;

final prefs = await SharedPreferences.getInstance();
await prefs.clear();

if (!mounted) return;

Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => const LoginPage()),
);
}

String obtenerSaludo() {
final hora = DateTime.now().hour;
if (hora >= 6 && hora < 12) return "Buenos días ☀️";
if (hora >= 12 && hora < 19) return "Buenas tardes 🌤️";
return "Buenas noches 🌙";
}

void _irAlPanel() {
if (rolUsuario == 'Administrador') {
Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage()));
} else if (rolUsuario == 'Supervisor') {
Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorPage()));
}
}

String get _etiquetaPanel {
if (rolUsuario == 'Administrador') return 'Panel Admin';
if (rolUsuario == 'Supervisor') return 'Panel Supervisor';
return '';
}

IconData get _iconoPanel {
if (rolUsuario == 'Administrador') return Icons.admin_panel_settings;
return Icons.supervisor_account;
}

@override
Widget build(BuildContext context) {
if (cargando) {
return const Scaffold(
backgroundColor: Color(0xFFF7F6F0),
body: Center(child: CircularProgressIndicator(color: Color(0xFF1E4620))),
);
}

final bool tienePanel = rolUsuario == 'Administrador' || rolUsuario == 'Supervisor';
const colorFondoApp = Color(0xFFF7F6F0);
const colorVerdeOscuro = Color(0xFF1E4620);
const colorVerdeClarito = Color(0xFFE2F0D9);
const colorBordeOro = Color(0xFFD4AF37);

return Scaffold(
backgroundColor: colorFondoApp,
appBar: AppBar(
backgroundColor: Colors.transparent,
elevation: 0,
title: const Text(
"Plagas Forestales",
style: TextStyle(color: colorVerdeOscuro, fontWeight: FontWeight.bold, fontSize: 24),
),
actions: [
IconButton(
icon: const Icon(Icons.logout, color: colorVerdeOscuro),
tooltip: 'Cerrar sesión',
onPressed: _confirmarCerrarSesion,
)
],
),
body: Stack(
children: [
// ── Fondo Ilustrativo Inferior ──
Positioned(
bottom: 0,
left: 0,
right: 0,
child: Opacity(
opacity: 0.9,
child: Image.asset(
'assets/images/bosque_background.png',
fit: BoxFit.contain,
errorBuilder: (context, error, stackTrace) {
return const SizedBox.shrink(); // Si no encuentra la imagen, no rompe la app
},
),
),
),

// ── Contenido Desplazable ──
SafeArea(
child: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.all(20.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// ── Tarjeta del Logo ──
Container(
width: double.infinity,
height: 180,
decoration: BoxDecoration(
color: const Color(0xFFFDFBF7),
border: Border.all(color: colorBordeOro, width: 2),
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.06),
blurRadius: 10,
offset: const Offset(0, 4),
)
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(14),
child: Container(
decoration: const BoxDecoration(
image: DecorationImage(
image: AssetImage('assets/images/textura_tarjeta.png'),
fit: BoxFit.cover,
),
),
child: Padding(
padding: const EdgeInsets.all(16),
child: Image.asset(
'assets/images/logoConafor.png',
fit: BoxFit.contain,
errorBuilder: (context, error, stackTrace) {
return const Center(
child: Text(
"CONAFOR",
style: TextStyle(color: colorVerdeOscuro, fontWeight: FontWeight.bold),
),
);
},
),
),
),
),
),

const SizedBox(height: 25),

// ── Banner de Saludo ──
Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
decoration: BoxDecoration(
color: colorVerdeClarito,
borderRadius: BorderRadius.circular(30),
),
child: Row(
children: [
const Icon(Icons.account_circle, color: colorVerdeOscuro, size: 26),
const SizedBox(width: 12),
Expanded(
child: Text(
"${obtenerSaludo()} $nombreUsuario",
style: const TextStyle(
color: colorVerdeOscuro,
fontSize: 16,
fontWeight: FontWeight.w600,
),
),
),
if (tienePanel)
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
decoration: BoxDecoration(
color: rolUsuario == 'Administrador' ? const Color(0xFF153316) : Colors.teal.shade700,
borderRadius: BorderRadius.circular(20),
),
child: Text(
rolUsuario,
style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
),
),
],
),
),

const SizedBox(height: 25),

const Text(
"Reporte Ciudadano de plagas forestales",
textAlign: TextAlign.center,
style: TextStyle(fontSize: 17, color: colorVerdeOscuro, fontWeight: FontWeight.w500),
),

const SizedBox(height: 35),

// ── Botón: Nuevo Reporte ──
SizedBox(
height: 58,
child: OutlinedButton.icon(
icon: const Icon(Icons.add, size: 24),
label: const Text("Nuevo Reporte"),
onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportePage())),
style: OutlinedButton.styleFrom(
foregroundColor: colorVerdeOscuro,
side: const BorderSide(color: colorVerdeOscuro, width: 1.5),
backgroundColor: Colors.white.withOpacity(0.85),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
),
),
),

const SizedBox(height: 16),

// ── Botón: Mis Reportes ──
SizedBox(
height: 58,
child: OutlinedButton.icon(
icon: const Icon(Icons.folder_open, size: 24),
label: const Text("Mis Reportes"),
onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MisReportesPage())),
style: OutlinedButton.styleFrom(
foregroundColor: colorVerdeOscuro,
side: const BorderSide(color: colorVerdeOscuro, width: 1.5),
backgroundColor: Colors.white.withOpacity(0.85),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
),
),
),

const SizedBox(height: 16),

// ── Botón: Panel Dinámico ──
if (tienePanel)
SizedBox(
height: 58,
child: ElevatedButton.icon(
icon: Icon(_iconoPanel, size: 24),
label: Text(_etiquetaPanel),
onPressed: _irAlPanel,
style: ElevatedButton.styleFrom(
backgroundColor: rolUsuario == 'Administrador' ? const Color(0xFF153316) : Colors.teal.shade700,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
),
),

const SizedBox(height: 120),
],
),
),
),
],
),
);
}
}
