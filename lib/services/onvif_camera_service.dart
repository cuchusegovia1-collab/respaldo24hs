import 'package:easy_onvif/onvif.dart';
import 'package:easy_onvif/probe.dart';
import 'package:easy_onvif/shared.dart' show PtzSpeed, Vector2D, Vector1D;

/// -----------------------------------------------------------------------
/// Este archivo fue verificado contra el código fuente real del paquete
/// `easy_onvif` versión 3.1.4 (repositorio:
/// https://github.com/faithoflifedev/easy_onvif_workspace), clonado y
/// revisado línea por línea para confirmar cada firma de método usada acá
/// abajo. Si en el futuro actualizás la dependencia a una versión mayor
/// (4.x en adelante) y algo deja de compilar, comparar contra ese
/// repositorio o contra https://pub.dev/documentation/easy_onvif/latest/
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
      final probe = MulticastProbe(timeout: timeout.inSeconds);
      await probe.probe();

      return probe.onvifDevices.map((match) {
        final ip = Uri.tryParse(match.xAddr)?.host ?? match.xAddr;
        return DiscoveredDevice(
          ip: ip,
          name: match.name.isNotEmpty ? match.name : null,
        );
      }).toList();
    } catch (_) {
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
      // getStreamUri ya devuelve el String de la URI directamente.
      return await onvif.media.getStreamUri(token);
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
        velocity: PtzSpeed(
          panTilt: Vector2D(x: pan, y: tilt),
          zoom: Vector1D(x: zoom),
        ),
      );
    } catch (_) {
      // La cámara puede no tener motor PTZ, o no soportar ContinuousMove
      // (algunos modelos solo soportan AbsoluteMove/RelativeMove).
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
