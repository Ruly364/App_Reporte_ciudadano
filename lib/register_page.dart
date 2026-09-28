import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'data/estados_municipios.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nombreCtrl      = TextEditingController();
  final emailCtrl       = TextEditingController();
  final passCtrl        = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  final telefonoCtrl    = TextEditingController();
  final edadCtrl        = TextEditingController();
  final etniaCtrl       = TextEditingController();

  String  genero             = "Prefiero no decirlo";
  bool    esEtnia            = false;
  bool    _verContrasena     = false;
  bool    _cargando          = false;
  bool    _contrasenasIguales = false;

  String  estadoSeleccionado    = estadosMunicipios.keys.first;
  String? municipioSeleccionado;
  List<String> municipiosFiltrados = [];

  static const _verde = Color(0xFF2D6A4F);
  static const _fondo = Color(0xFFF0F4F0);

  @override
  void initState() {
    super.initState();
    municipiosFiltrados = estadosMunicipios[estadoSeleccionado]!;
    // Escucha cambios en ambos campos para el indicador en tiempo real
    passCtrl.addListener(_verificarContrasenas);
    confirmPassCtrl.addListener(_verificarContrasenas);
  }

  void _verificarContrasenas() {
    final iguales = passCtrl.text.isNotEmpty &&
        passCtrl.text == confirmPassCtrl.text;
    if (iguales != _contrasenasIguales) {
      setState(() => _contrasenasIguales = iguales);
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    telefonoCtrl.dispose();
    edadCtrl.dispose();
    etniaCtrl.dispose();
    super.dispose();
  }

  // ── Decoración de campo individual ────────────────────────
  InputDecoration _decoPlain(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
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

  // ── Tarjeta agrupadora de campos ───────────────────────────
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
        return Column(
          children: [
            e.value,
            if (!isLast)
              Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
          ],
        );
      }).toList(),
    ),
  );

  // ── Campo dentro de tarjeta ────────────────────────────────
  Widget _cardField(
      TextEditingController ctrl,
      String hint,
      IconData icon, {
        TextInputType? keyboardType,
        bool obscure = false,
        Widget? suffix,
      }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: _decoPlain(hint, icon, suffix: suffix),
        ),
      );

  // ── Etiqueta de sección ────────────────────────────────────
  Widget _sectionLabel(String texto) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
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

  // ── Indicador contraseñas coinciden ───────────────────────
  Widget _matchIndicator() {
    if (confirmPassCtrl.text.isEmpty) return const SizedBox.shrink();
    final ok = _contrasenasIguales;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: ok ? const Color(0xFF27500A) : const Color(0xFFA32D2D),
          ),
          const SizedBox(width: 6),
          Text(
            ok ? 'Las contraseñas coinciden' : 'Las contraseñas no coinciden',
            style: TextStyle(
              fontSize: 12,
              color: ok ? const Color(0xFF27500A) : const Color(0xFFA32D2D),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chips ──────────────────────────────────────────────────
  Widget _chipGroup<T>({
    required List<T> opciones,
    required T seleccionado,
    required String Function(T) label,
    required void Function(T) onTap,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: opciones.map((op) {
          final activo = op == seleccionado;
          return GestureDetector(
            onTap: () => onTap(op),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: activo ? _verde : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activo ? _verde : Colors.black12,
                  width: activo ? 1.5 : 0.5,
                ),
              ),
              child: Text(
                label(op),
                style: TextStyle(
                  fontSize: 13,
                  color: activo ? Colors.white : Colors.grey[700],
                  fontWeight:
                  activo ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      );

  // ── Decoración dropdown ────────────────────────────────────
  InputDecoration _dropDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    prefixIcon: Icon(icon, color: Colors.grey[400]),
    filled: true,
    fillColor: Colors.white,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    contentPadding:
    const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
  );

  // ── Registro ───────────────────────────────────────────────
  Future<void> _registrar() async {
    if (nombreCtrl.text
        .trim()
        .isEmpty ||
        passCtrl.text
            .trim()
            .isEmpty) {
      _snack('Nombre y contraseña son obligatorios');
      return;
    }
    if (passCtrl.text.length < 6) {
      _snack('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (!_contrasenasIguales) {
      _snack('Las contraseñas no coinciden');
      return;
    }
    if (municipioSeleccionado == null) {
      _snack('Selecciona un municipio');
      return;
    }

    setState(() => _cargando = true);
    try {
      final resultado = await AuthService.register(
        nombreCtrl.text.trim(),
        emailCtrl.text.isEmpty ? null : emailCtrl.text.trim(),
        telefonoCtrl.text.isEmpty ? null : telefonoCtrl.text.trim(),
        passCtrl.text,
        int.tryParse(edadCtrl.text) ?? 0,
        genero,
        estadoSeleccionado,
        municipioSeleccionado!,
        esEtnia,
        etniaCtrl.text,
      );
      if (resultado == "OK") {
        _snack('Usuario registrado correctamente');

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _snack(resultado);
      }
    } catch (e) {
      _snack('Error de conexión');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Botón ojo compartido ───────────────────────────────────
  Widget get _eyeBtn => IconButton(
    icon: Icon(
      _verContrasena
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined,
      color: Colors.grey[400],
    ),
    onPressed: () =>
        setState(() => _verContrasena = !_verContrasena),
  );

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crear cuenta',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20, 4, 20,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Datos personales ───────────────────────────
              _sectionLabel('Datos personales'),
              _fieldCard([
                _cardField(nombreCtrl, 'Nombre completo',
                    Icons.person_outline_rounded),
                _cardField(emailCtrl, 'Correo electrónico',
                    Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress),
                _cardField(telefonoCtrl, 'Teléfono',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                _cardField(edadCtrl, 'Edad',
                    Icons.cake_outlined,
                    keyboardType: TextInputType.number),
              ]),

              // ── Seguridad ──────────────────────────────────
              _sectionLabel('Seguridad'),
              _fieldCard([
                _cardField(passCtrl, 'Contraseña',
                    Icons.lock_outline_rounded,
                    obscure: !_verContrasena,
                    suffix: _eyeBtn),
                _cardField(confirmPassCtrl, 'Confirmar contraseña',
                    Icons.lock_clock_outlined,
                    obscure: !_verContrasena,
                    suffix: _eyeBtn),
              ]),
              _matchIndicator(),

              // ── Género ─────────────────────────────────────
              _sectionLabel('Género'),
              _chipGroup<String>(
                opciones: ['Hombre', 'Mujer', 'Prefiero no decirlo'],
                seleccionado: genero,
                label: (g) => g,
                onTap: (g) => setState(() => genero = g),
              ),

              // ── Etnia ──────────────────────────────────────
              _sectionLabel('Pertenencia étnica'),
              _chipGroup<bool>(
                opciones: [true, false],
                seleccionado: esEtnia,
                label: (v) => v ? 'Sí' : 'No',
                onTap: (v) => setState(() {
                  esEtnia = v;
                  if (!v) etniaCtrl.clear();
                }),
              ),
              if (esEtnia) ...[
                const SizedBox(height: 10),
                _fieldCard([
                  _cardField(etniaCtrl, '¿Cuál etnia?',
                      Icons.groups_outlined),
                ]),
              ],

              // ── Ubicación ──────────────────────────────────
              _sectionLabel('Ubicación'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12, width: 0.5),
                ),
                child: Column(
                  children: [
                    // Estado
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonFormField<String>(
                        value: estadoSeleccionado,
                        decoration: _dropDeco('Estado', Icons.map_outlined),
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey[400]),
                        items: estadosMunicipios.keys
                            .map((e) => DropdownMenuItem(
                            value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) => setState(() {
                          estadoSeleccionado  = value!;
                          municipiosFiltrados = estadosMunicipios[value]!;
                          municipioSeleccionado = null;
                        }),
                      ),
                    ),
                    Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.grey[200]),
                    // Municipio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(estadoSeleccionado),
                        value: municipioSeleccionado,
                        decoration:
                        _dropDeco('Municipio', Icons.location_on_outlined),
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey[400]),
                        items: municipiosFiltrados
                            .map((m) => DropdownMenuItem(
                            value: m, child: Text(m)))
                            .toList(),
                        onChanged: (value) => setState(
                                () => municipioSeleccionado = value),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Botón ──────────────────────────────────────
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _cargando
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Registrarse',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}