import 'package:easy_onvif/onvif.dart';

/// -----------------------------------------------------------------------
/// NOTA IMPORTANTE PARA QUIEN CONTINÚE ESTE CÓDIGO
/// -----------------------------------------------------------------------
/// Este archivo se escribió sin poder compilarlo ni ejecutarlo contra un
/// dispositivo real (el entorno donde se generó no tiene el SDK de Flutter
/// ni acceso a pub.dev). La forma general de la API de `easy_onvif`
/// (clases Onvif / media / ptz / probe) está confirmada por su
/// documentación pública, pero los nombres exactos de métodos y
/// parámetros han cambiado entre versiones del paquete (el propio
/// changelog de easy_onvif lo advierte). Antes de dar por bueno este
/// archivo:
///   1. Corré `flutter pub get`.
///   2. Si el compilador marca un método o parámetro como inexistente,
///      abrí la documentación de la versión instalada:
///      https://pub.dev/documentation/easy_onvif/latest/
///   3. Ajustá solo esta clase — el resto de la app no depende de los
///      detalles internos de easy_onvif, solo de los métodos públicos
///      de OnvifCameraService de más abajo.
/// -----------------------------------------------------------------------

/// Resultado de un dispositivo encontrado en la red local vía WS-Discovery.
class DiscoveredDevice {
  final String ip;
  final String? name;
  DiscoveredDevice({required this.ip, this.name});
}

/// Envuelve toda la interacción ONVIF: descubrir cámaras en la LAN,
/// obtener la URI de streaming real (en vez de adivinar la ruta RTSP),
/// y mover la cámara si soporta PTZ.
class OnvifCameraService {
  /// Busca dispositivos ONVIF en la red local (multicast WS-Discovery).
  /// Devuelve lista vacía si no hay respuestas dentro del timeout,
  /// lo cual es normal si la cámara solo habla el protocolo P2P cerrado
  /// de iCSee/V380 (en ese caso no hay integración posible sin depender
  /// igualmente de un servidor P2P propio).
  Future<List<DiscoveredDevice>> discoverOnLan({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final probeResults = await Onvif.probe(timeout: timeout);
      return probeResults
          .map((d) => DiscoveredDevice(ip: d.address, name: d.name))
          .toList();
    } catch (_) {
      // Alguna versiones exponen el probe como `Probe.discover(...)` en vez
      // de `Onvif.probe(...)`. Si esto falla al compilar, revisar el import
      // `package:easy_onvif/probe.dart` y ajustar la llamada.
      return [];
    }
  }

  /// Se conecta a la cámara y devuelve la URI RTSP real que reporta el
  /// propio dispositivo (más confiable que adivinar la ruta por marca).
  /// Devuelve null si el dispositivo no respondió a ONVIF (cámara P2P-only,
  /// credenciales incorrectas, o puerto ONVIF bloqueado).
  Future<String?> resolveStreamUri({
    required String ip,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final onvif = await Onvif.connect(
        host: '$ip:$port',
        username: username,
        password: password,
      );

      final profiles = await onvif.media.getProfiles();
      if (profiles.isEmpty) return null;

      final token = profiles.first.token;
      final streamUri = await onvif.media.getStreamUri(token);
      return streamUri.uri;
    } catch (_) {
      return null;
    }
  }

  /// Mueve la cámara en modo continuo mientras se mantiene presionado un
  /// botón de dirección. `pan` y `tilt` van de -1.0 a 1.0.
  Future<void> continuousMove({
    required String ip,
    required int port,
    required String username,
    required String password,
    required double pan,
    required double tilt,
    double zoom = 0,
  }) async {
    try {
      final onvif = await Onvif.connect(
        host: '$ip:$port',
        username: username,
        password: password,
      );
      final profiles = await onvif.media.getProfiles();
      if (profiles.isEmpty) return;
      final token = profiles.first.token;

      await onvif.ptz.continuousMove(
        token,
        panTilt: PtzSpeed(x: pan, y: tilt),
        zoom: PtzSpeed(x: zoom, y: 0),
      );
    } catch (_) {
      // La cámara puede no tener motor PTZ, o el modelo puede exponer
      // el movimiento con otra firma de método según la versión instalada.
    }
  }

  /// Detiene el movimiento PTZ (se llama al soltar el botón).
  Future<void> stopMove({
    required String ip,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final onvif = await Onvif.connect(
        host: '$ip:$port',
        username: username,
        password: password,
      );
      final profiles = await onvif.media.getProfiles();
      if (profiles.isEmpty) return;
      await onvif.ptz.stop(profiles.first.token);
    } catch (_) {
      // Ídem nota anterior.
    }
  }
}
