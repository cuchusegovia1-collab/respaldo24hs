import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/camera_device.dart';
import '../providers/camera_provider.dart';
import '../theme/app_theme.dart';

class CameraSettingsScreen extends StatefulWidget {
  final CameraDevice camera;
  const CameraSettingsScreen({super.key, required this.camera});

  @override
  State<CameraSettingsScreen> createState() => _CameraSettingsScreenState();
}

class _CameraSettingsScreenState extends State<CameraSettingsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ipCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.camera.name);
    _ipCtrl = TextEditingController(text: widget.camera.ip);
    _userCtrl = TextEditingController(text: widget.camera.username);
    _passCtrl = TextEditingController(text: widget.camera.password);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.camera
      ..name = _nameCtrl.text.trim()
      ..ip = _ipCtrl.text.trim()
      ..username = _userCtrl.text
      ..password = _passCtrl.text;

    await context.read<CameraProvider>().updateCamera(updated);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cámara'),
        content: Text('¿Eliminar "${widget.camera.name}" de Respaldo 24 HS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<CameraProvider>().deleteCamera(widget.camera.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de cámara')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ipCtrl,
            decoration: const InputDecoration(labelText: 'Dirección IP'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userCtrl,
            decoration: const InputDecoration(labelText: 'Usuario'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Guardar cambios'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _confirmDelete,
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Eliminar cámara'),
            ),
          ),
        ],
      ),
    );
  }
}
