import 'package:flutter/material.dart';
import '../models/camera_device.dart';
import '../theme/app_theme.dart';

class CameraCard extends StatelessWidget {
  final CameraDevice camera;
  final VoidCallback onTap;
  final VoidCallback onSettingsTap;

  const CameraCard({
    super.key,
    required this.camera,
    required this.onTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    Icons.videocam_rounded,
                    size: 40,
                    color: camera.onvifReachable
                        ? AppTheme.accent
                        : AppTheme.textSecondary.withOpacity(0.4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          camera.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          camera.ip,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    color: AppTheme.textSecondary,
                    onPressed: onSettingsTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
