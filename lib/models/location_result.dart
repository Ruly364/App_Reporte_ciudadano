import 'location_quality.dart';
import 'location_source.dart';

/// ===============================================================
/// LOCATION RESULT
/// ---------------------------------------------------------------
///
/// Representa UNA lectura GPS.
///
/// Puede provenir de:
///
/// • GPS interno
/// • GNSS externo
/// • Garmin
/// • RTK
/// • Simulación
///
/// Esta clase NO contiene lógica.
///
/// ===============================================================

class LocationResult {

  //--------------------------------------------------------------
  // POSICIÓN
  //--------------------------------------------------------------

  final double latitude;

  final double longitude;

  final double altitude;

  //--------------------------------------------------------------
  // PRECISIÓN
  //--------------------------------------------------------------

  /// Precisión horizontal (metros)
  final double accuracy;

  /// Precisión vertical (metros)
  final double? verticalAccuracy;

  //--------------------------------------------------------------
  // RUMBO
  //--------------------------------------------------------------

  final double heading;

  //--------------------------------------------------------------
  // VELOCIDAD
  //--------------------------------------------------------------

  final double speed;

  //--------------------------------------------------------------
  // INFORMACIÓN GPS
  //--------------------------------------------------------------

  final LocationSource source;

  final LocationQuality quality;

  //--------------------------------------------------------------
  // FUTURO (GNSS)
  //--------------------------------------------------------------

  final int satellites;

  final double? hdop;

  final double? vdop;

  final double? pdop;

  final bool rtkFix;

  //--------------------------------------------------------------
  // TIEMPO
  //--------------------------------------------------------------

  final DateTime timestamp;

  const LocationResult({

    required this.latitude,

    required this.longitude,

    required this.altitude,

    required this.accuracy,

    this.verticalAccuracy,

    required this.heading,

    required this.speed,

    required this.source,

    required this.quality,

    this.satellites = 0,

    this.hdop,

    this.vdop,

    this.pdop,

    this.rtkFix = false,

    required this.timestamp,

  });

  //--------------------------------------------------------------
  // JSON
  //--------------------------------------------------------------

  Map<String, dynamic> toJson() {

    return {

      "latitude": latitude,

      "longitude": longitude,

      "altitude": altitude,

      "accuracy": accuracy,

      "verticalAccuracy": verticalAccuracy,

      "heading": heading,

      "speed": speed,

      "source": source.name,

      "quality": quality.name,

      "satellites": satellites,

      "hdop": hdop,

      "vdop": vdop,

      "pdop": pdop,

      "rtkFix": rtkFix,

      "timestamp": timestamp.toIso8601String(),

    };

  }

  //--------------------------------------------------------------
  // COPY WITH
  //--------------------------------------------------------------

  LocationResult copyWith({

    double? latitude,

    double? longitude,

    double? altitude,

    double? accuracy,

    double? verticalAccuracy,

    double? heading,

    double? speed,

    LocationSource? source,

    LocationQuality? quality,

    int? satellites,

    double? hdop,

    double? vdop,

    double? pdop,

    bool? rtkFix,

    DateTime? timestamp,

  }) {

    return LocationResult(

      latitude: latitude ?? this.latitude,

      longitude: longitude ?? this.longitude,

      altitude: altitude ?? this.altitude,

      accuracy: accuracy ?? this.accuracy,

      verticalAccuracy:
      verticalAccuracy ?? this.verticalAccuracy,

      heading: heading ?? this.heading,

      speed: speed ?? this.speed,

      source: source ?? this.source,

      quality: quality ?? this.quality,

      satellites: satellites ?? this.satellites,

      hdop: hdop ?? this.hdop,

      vdop: vdop ?? this.vdop,

      pdop: pdop ?? this.pdop,

      rtkFix: rtkFix ?? this.rtkFix,

      timestamp: timestamp ?? this.timestamp,

    );

  }

  //--------------------------------------------------------------
  // DEBUG
  //--------------------------------------------------------------

  @override
  String toString() {

    return '''

LocationResult

Latitude : $latitude

Longitude: $longitude

Altitude : $altitude

Accuracy : ${accuracy.toStringAsFixed(2)} m

Heading  : ${heading.toStringAsFixed(1)}

Speed    : ${speed.toStringAsFixed(2)}

Source   : ${source.name}

Quality  : ${quality.name}

Satellites : $satellites

HDOP       : ${hdop ?? "-"}

PDOP       : ${pdop ?? "-"}

VDOP       : ${vdop ?? "-"}

RTK FIX    : $rtkFix

Timestamp  : $timestamp

''';

  }

}