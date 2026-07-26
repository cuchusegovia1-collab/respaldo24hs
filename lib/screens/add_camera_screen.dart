import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/camera_device.dart';
import '../providers/camera_provider.dart';
import '../services/onvif_camera_service.dart';

class AddCameraScreen extends StatefulWidget {
  const AddCameraScreen({super.key});

  @override
  State<AddCameraScreen> createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  final _onvifService = OnvifCameraService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _onvifPortCtrl = TextEditingController(text: '8899');
  final _rtspPortCtrl = TextEditingController(text: '554');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  RtspPathTemplate _template = RtspPathTemplate.onvifAuto;

  bool _scanning = false;
  bool _testing = false;
  List<DiscoveredDevice> _found = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _onvifPortCtrl.dispose();
    _rtspPortCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanLan() async {
    setState(() => _scanning = true);
    final results = await _onvifService.discoverOnLan();
    setState(() {
      _found = results;
      _scanning = false;
    });

    if (results.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontraron cámaras ONVIF en la red. Si tu cámara solo '
            'funciona con la app original, probá agregarla manualmente con su IP.',
          ),
        ),
      );
    }
  }

  void _prefillFromDiscovery(DiscoveredDevice device) {
    _ipCtrl.text = device.ip;
    _nameCtrl.text = device.name ?? 'Cámara ${device.ip}';
  }

  Future<void> _testAndResolveStream() async {
    if (_ipCtrl.text.isEmpty) return;
    setState(() => _testing = true);

    final uri = await _onvifService.resolveStreamUri(
      ip: _ipCtrl.text.trim(),
      port: int.tryParse(_onvifPortCtrl.text) ?? 8899,
      username: _userCtrl.text,
      password: _passCtrl.text,
    );

    setState(() => _testing = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uri != null
              ? 'ONVIF respondió correctamente. Se usará la URI real del dispositivo.'
              : 'No se pudo confirmar por ONVIF. Se usará la plantilla de ruta '
                  'seleccionada como respaldo.',
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<CameraProvider>();

    final resolvedUri = await _onvifService.resolveStreamUri(
      ip: _ipCtrl.text.trim(),
      port: int.tryParse(_onvifPortCtrl.text) ?? 8899,
      username: _userCtrl.text,
      password: _passCtrl.text,
    );

    final camera = CameraDevice(
      id: provider.newId(),
      name: _nameCtrl.text.trim(),
      ip: _ipCtrl.text.trim(),
      onvifPort: int.tryParse(_onvifPortCtrl.text) ?? 8899,
      rtspPort: int.tryParse(_rtspPortCtrl.text) ?? 554,
      username: _userCtrl.text,
      password: _passCtrl.text,
      pathTemplate: _template,
      resolvedRtspPath: resolvedUri,
      onvifReachable: resolvedUri != null,
    );

    await provider.addCamera(camera);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar cámara')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Buscar en la red local', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _scanning ? null : _scanLan,
            icon: _scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find_rounded),
            label: Text(_scanning ? 'Buscando...' : 'Buscar cámaras ONVIF'),
          ),
          if (_found.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._found.map(
              (d) => Card(
                child: ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: Text(d.name ?? d.ip),
                  subtitle: Text(d.ip),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => setState(() => _prefillFromDiscovery(d)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Datos de la cámara', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ipCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección IP'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _onvifPortCtrl,
                        decoration: const InputDecoration(labelText: 'Puerto ONVIF'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rtspPortCtrl,
                        decoration: const InputDecoration(labelText: 'Puerto RTSP'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RtspPathTemplate>(
                  initialValue: _template,
                  decoration: const InputDecoration(
                    labelText: 'Ruta RTSP de respaldo (si ONVIF no responde)',
                  ),
                  items: RtspPathTemplate.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _template = v ?? _template),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _testing ? null : _testAndResolveStream,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering_rounded),
                  label: Text(_testing ? 'Probando...' : 'Probar conexión ONVIF'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Guardar cámara'),
            ),
          ),
        ],
      ),
    );
  }
}
