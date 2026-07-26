import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_card.dart';
import 'add_camera_screen.dart';
import 'camera_settings_screen.dart';
import 'live_view_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldo 24 HS'),
      ),
      body: Consumer<CameraProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cameras.isEmpty) {
            return _EmptyState(
              onAdd: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddCameraScreen()),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: provider.cameras.length,
            itemBuilder: (context, index) {
              final camera = provider.cameras[index];
              return CameraCard(
                camera: camera,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LiveViewScreen(camera: camera),
                  ),
                ),
                onSettingsTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CameraSettingsScreen(camera: camera),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddCameraScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar cámara'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Todavía no agregaste ninguna cámara',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Buscá cámaras en tu red WiFi o agregalas manualmente con su IP.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar cámara'),
            ),
          ],
        ),
      ),
    );
  }
}
