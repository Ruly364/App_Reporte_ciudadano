class TipoPlaga {
  final int id;
  final String nombre;

  TipoPlaga({required this.id, required this.nombre});

  factory TipoPlaga.fromJson(Map<String, dynamic> json) {
    return TipoPlaga(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}