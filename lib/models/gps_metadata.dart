/// ===============================================================
/// GPS METADATA
/// ---------------------------------------------------------------
///
/// Información del dispositivo y del proveedor GPS.
///
/// Esta clase almacena datos del hardware utilizado
/// durante una captura.
///
/// Compatible con:
///
/// • GPS interno Android
/// • Garmin GLO / GLO2
/// • Bad Elf
/// • RTK
/// • GNSS Bluetooth
///
/// ===============================================================

class GpsMetadata {

  //--------------------------------------------------------------
  // PROVEEDOR
  //--------------------------------------------------------------

  /// Android GPS
  /// Garmin GLO
  /// RTK
  /// Bad Elf
  final String provider;

  //--------------------------------------------------------------
  // DISPOSITIVO
  //--------------------------------------------------------------

  final String manufacturer;

  final String model;

  final String device;

  //--------------------------------------------------------------
  // SISTEMA
  //--------------------------------------------------------------

  final String osVersion;

  final String appVersion;

  //--------------------------------------------------------------
  // INFORMACIÓN GNSS
  //--------------------------------------------------------------

  final int satellites;

  final double? hdop;

  final double? vdop;

  final double? pdop;

  final bool rtkFix;

  //--------------------------------------------------------------
  // GPS INTERNO / EXTERNO
  //--------------------------------------------------------------

  final bool externalReceiver;

  //--------------------------------------------------------------
  // FECHA
  //--------------------------------------------------------------

  final DateTime timestamp;

  //--------------------------------------------------------------
  // CONSTRUCTOR
  //--------------------------------------------------------------

  const GpsMetadata({

    required this.provider,

    required this.manufacturer,

    required this.model,

    required this.device,

    required this.osVersion,

    required this.appVersion,

    this.satellites = 0,

    this.hdop,

    this.vdop,

    this.pdop,

    this.rtkFix = false,

    this.externalReceiver = false,

    required this.timestamp,

  });

  //--------------------------------------------------------------
  // COPY WITH
  //--------------------------------------------------------------

  GpsMetadata copyWith({

    String? provider,

    String? manufacturer,

    String? model,

    String? device,

    String? osVersion,

    String? appVersion,

    int? satellites,

    double? hdop,

    double? vdop,

    double? pdop,

    bool? rtkFix,

    bool? externalReceiver,

    DateTime? timestamp,

  }) {

    return GpsMetadata(

      provider: provider ?? this.provider,

      manufacturer: manufacturer ?? this.manufacturer,

      model: model ?? this.model,

      device: device ?? this.device,

      osVersion: osVersion ?? this.osVersion,

      appVersion: appVersion ?? this.appVersion,

      satellites: satellites ?? this.satellites,

      hdop: hdop ?? this.hdop,

      vdop: vdop ?? this.vdop,

      pdop: pdop ?? this.pdop,

      rtkFix: rtkFix ?? this.rtkFix,

      externalReceiver:
      externalReceiver ?? this.externalReceiver,

      timestamp: timestamp ?? this.timestamp,

    );

  }

  //--------------------------------------------------------------
  // JSON
  //--------------------------------------------------------------

  Map<String, dynamic> toJson() {

    return {

      "provider": provider,

      "manufacturer": manufacturer,

      "model": model,

      "device": device,

      "osVersion": osVersion,

      "appVersion": appVersion,

      "satellites": satellites,

      "hdop": hdop,

      "vdop": vdop,

      "pdop": pdop,

      "rtkFix": rtkFix,

      "externalReceiver": externalReceiver,

      "timestamp": timestamp.toIso8601String(),

    };

  }

  //--------------------------------------------------------------
  // FROM JSON
  //--------------------------------------------------------------

  factory GpsMetadata.fromJson(
      Map<String, dynamic> json) {

    return GpsMetadata(

      provider: json["provider"],

      manufacturer: json["manufacturer"],

      model: json["model"],

      device: json["device"],

      osVersion: json["osVersion"],

      appVersion: json["appVersion"],

      satellites: json["satellites"] ?? 0,

      hdop: (json["hdop"] as num?)?.toDouble(),

      vdop: (json["vdop"] as num?)?.toDouble(),

      pdop: (json["pdop"] as num?)?.toDouble(),

      rtkFix: json["rtkFix"] ?? false,

      externalReceiver:
      json["externalReceiver"] ?? false,

      timestamp:
      DateTime.parse(json["timestamp"]),

    );

  }

  //--------------------------------------------------------------
  // DEBUG
  //--------------------------------------------------------------

  @override
  String toString() {

    return '''

==============================

GPS METADATA

==============================

Provider............ $provider

Manufacturer........ $manufacturer

Model............... $model

Device.............. $device

OS.................. $osVersion

App Version......... $appVersion

Satellites.......... $satellites

HDOP................ ${hdop ?? "-"}

VDOP................ ${vdop ?? "-"}

PDOP................ ${pdop ?? "-"}

RTK FIX............. $rtkFix

External Receiver... $externalReceiver

Timestamp........... $timestamp

==============================

''';

  }

}