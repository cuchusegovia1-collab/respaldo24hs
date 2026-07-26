import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pad direccional para control PTZ. Llama a `onStart` mientras se
/// mantiene presionado y `onStop` al soltar, tal como espera el
/// comando ContinuousMove de ONVIF.
class PtzControlPad extends StatelessWidget {
  final void Function(double pan, double tilt) onStart;
  final VoidCallback onStop;

  const PtzControlPad({
    super.key,
    required this.onStart,
    required this.onStop,
  });

  Widget _button(IconData icon, double pan, double tilt) {
    return GestureDetector(
      onTapDown: (_) => onStart(pan, tilt),
      onTapUp: (_) => onStop(),
      onTapCancel: onStop,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.keyboard_arrow_up_rounded, 0, 1),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(Icons.keyboard_arrow_left_rounded, -1, 0),
            const SizedBox(width: 6),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
              ),
            ),
            const SizedBox(width: 6),
            _button(Icons.keyboard_arrow_right_rounded, 1, 0),
          ],
        ),
        const SizedBox(height: 6),
        _button(Icons.keyboard_arrow_down_rounded, 0, -1),
      ],
    );
  }
}
