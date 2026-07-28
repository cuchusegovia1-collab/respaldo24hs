import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:path_provider/path_provider.dart';
import '../models/camera_device.dart';
import '../services/onvif_camera_service.dart';
import '../widgets/ptz_control_pad.dart';

class LiveViewScreen extends StatefulWidget {
  final CameraDevice camera;
  const LiveViewScreen({super.key, required this.camera});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  late final VlcPlayerController _controller;
  final _onvifService = OnvifCameraService();
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _controller = VlcPlayerController.network(
      widget.camera.rtspUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        // Baja la latencia para uso de vigilancia en vivo.
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(300),
        ]),
        rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
      ),
    );
  }

  @override
  void dispose() {
    _controller.stopRendererScanning();
    _controller.dispose();
    super.dispose();
  }

  void _onPtzStart(double pan, double tilt) {
    final c = widget.camera;
    _onvifService.continuousMove(
      ip: c.ip,
      port: c.onvifPort,
      username: c.username,
      password: c.password,
      pan: pan,
      tilt: tilt,
    );
  }

  void _onPtzStop() {
    final c = widget.camera;
    _onvifService.stopMove(
      ip: c.ip,
      port: c.onvifPort,
      username: c.username,
      password: c.password,
    );
  }

  Future<void> _takeSnapshot() async {
    try {
      // takeSnapshot() sólo devuelve los bytes de la imagen en memoria;
      // hay que escribirlos a un archivo para que quede realmente guardada.
      final bytes = await _controller.takeSnapshot();
      if (bytes == null) throw Exception('Sin datos de imagen');

      final dir = await getApplicationDocumentsDirectory();
      final snapshotsDir = Directory('${dir.path}/respaldo24hs_capturas');
      if (!await snapshotsDir.exists()) {
        await snapshotsDir.create(recursive: true);
      }

      final fileName = 'captura_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${snapshotsDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Captura guardada: $fileName')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo capturar la imagen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.camera.name)),
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: VlcPlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
                placeholder: const Center(child: CircularProgressIndicator()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      _controller.setVolume(_muted ? 0 : 100);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined),
                    onPressed: _takeSnapshot,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: PtzControlPad(onStart: _onPtzStart, onStop: _onPtzStop),
            ),
          ],
        ),
      ),
    );
  }
}
