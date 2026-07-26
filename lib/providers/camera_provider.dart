import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/camera_device.dart';
import '../services/camera_storage_service.dart';

/// Fuente única de verdad para la lista de cámaras guardadas.
/// Todas las pantallas escuchan este provider en vez de leer
/// directamente el almacenamiento local.
class CameraProvider extends ChangeNotifier {
  final CameraStorageService _storage = CameraStorageService();
  final _uuid = const Uuid();

  List<CameraDevice> _cameras = [];
  bool _loading = true;

  List<CameraDevice> get cameras => List.unmodifiable(_cameras);
  bool get loading => _loading;

  CameraProvider() {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    _cameras = await _storage.loadAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> addCamera(CameraDevice camera) async {
    _cameras.add(camera);
    notifyListeners();
    await _storage.saveAll(_cameras);
  }

  Future<void> updateCamera(CameraDevice updated) async {
    final index = _cameras.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    _cameras[index] = updated;
    notifyListeners();
    await _storage.saveAll(_cameras);
  }

  Future<void> deleteCamera(String id) async {
    _cameras.removeWhere((c) => c.id == id);
    notifyListeners();
    await _storage.saveAll(_cameras);
  }

  String newId() => _uuid.v4();
}
