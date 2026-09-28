class DireccionGPS {

  final String estado;

  final String municipio;

  final String localidad;

  final bool obtenidoDesdeCache;

  final bool obtenidoDesdeInternet;

  const DireccionGPS({

    required this.estado,

    required this.municipio,

    required this.localidad,

    this.obtenidoDesdeCache = false,

    this.obtenidoDesdeInternet = false,

  });

}