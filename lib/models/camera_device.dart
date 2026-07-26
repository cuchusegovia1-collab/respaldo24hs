/// Plantillas conocidas de ruta RTSP usadas por distintas familias de
/// cámaras OEM (las mismas que traen apps como iCSee o V380 Pro).
/// Se usan como respaldo cuando el descubrimiento ONVIF no puede
/// entregar la URI de stream real (GetStreamUri).
enum RtspPathTemplate {
  onvifAuto('Automático (ONVIF GetStreamUri)', null),
  icseeStyle('Estilo iCSee', '/onvif1'),
  v380Style('Estilo V380 / V380 Pro', '/live/ch00_0'),
  hikCompatible('Compatible Hikvision/Dahua genérico', '/Streaming/Channels/101'),
  custom('Personalizado', '');

  final String label;
  final String? path;
  const RtspPathTemplate(this.label, this.path);
}

/// Representa una cámara guardada por el usuario.
/// Todo se guarda localmente (no hay cuenta ni nube): ese es el punto
/// de partida de privacidad de Respaldo 24 HS frente a las apps originales.
class CameraDevice {
  final String id;
  String name;
  String ip;

  /// Puerto ONVIF típico: 8899 (genéricas), 80 (Hik/Dahua), 8000, etc.
  int onvifPort;

  /// Puerto RTSP típico: 554.
  int rtspPort;

  String username;
  String password;

  /// Plantilla de ruta usada si no se pudo resolver por ONVIF.
  RtspPathTemplate pathTemplate;

  /// Ruta RTSP resuelta manualmente o cacheada tras un GetStreamUri exitoso.
  String? resolvedRtspPath;

  /// true si en el último intento el dispositivo respondió al protocolo ONVIF.
  bool onvifReachable;

  CameraDevice({
    required this.id,
    required this.name,
    required this.ip,
    this.onvifPort = 8899,
    this.rtspPort = 554,
    this.username = '',
    this.password = '',
    this.pathTemplate = RtspPathTemplate.onvifAuto,
    this.resolvedRtspPath,
    this.onvifReachable = false,
  });

  /// URL RTSP final a reproducir. Prioriza la ruta resuelta por ONVIF;
  /// si no hay ninguna, cae en la plantilla elegida.
  String get rtspUrl {
    final path = resolvedRtspPath ??
        (pathTemplate.path?.isNotEmpty == true ? pathTemplate.path : '/live/ch00_0');
    final auth = (username.isNotEmpty) ? '$username:$password@' : '';
    return 'rtsp://$auth$ip:$rtspPort$path';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'onvifPort': onvifPort,
        'rtspPort': rtspPort,
        'username': username,
        'password': password,
        'pathTemplate': pathTemplate.name,
        'resolvedRtspPath': resolvedRtspPath,
        'onvifReachable': onvifReachable,
      };

  factory CameraDevice.fromJson(Map<String, dynamic> json) => CameraDevice(
        id: json['id'] as String,
        name: json['name'] as String,
        ip: json['ip'] as String,
        onvifPort: json['onvifPort'] as int? ?? 8899,
        rtspPort: json['rtspPort'] as int? ?? 554,
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        pathTemplate: RtspPathTemplate.values.firstWhere(
          (e) => e.name == json['pathTemplate'],
          orElse: () => RtspPathTemplate.onvifAuto,
        ),
        resolvedRtspPath: json['resolvedRtspPath'] as String?,
        onvifReachable: json['onvifReachable'] as bool? ?? false,
      );
}
