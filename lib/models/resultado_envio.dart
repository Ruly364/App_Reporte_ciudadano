class ResultadoEnvio {
  final bool enviado;
  final String? folio;
  final String mensaje;

  const ResultadoEnvio({
    required this.enviado,
    this.folio,
    required this.mensaje,
  });
}