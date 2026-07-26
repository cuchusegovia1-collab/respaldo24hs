import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camera_device.dart';

/// Guarda el listado de cámaras únicamente en el dispositivo del usuario.
/// Respaldo 24 HS no usa cuentas ni servidores propios: nada de esto
/// sale del teléfono salvo la conexión directa (LAN u ONVIF/RTSP) hacia
/// la propia cámara.
class CameraStorageService {
  static const _storageKey = 'respaldo24hs.cameras';

  Future<List<CameraDevice>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(raw);
    return decoded
        .map((e) => CameraDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<CameraDevice> cameras) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(cameras.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
