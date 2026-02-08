// widgets/waveform_bar.dart
import 'package:flutter/material.dart';
import '../app/theme.dart';

class WaveformBar extends StatelessWidget {
  final List<double> values;
  final double height;
  final double progress; // 0..1 (UI mock)

  const WaveformBar({
    super.key,
    required this.values,
    this.height = 34,
    this.progress = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    final orange = AppTheme.soundCloudOrange;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: (values[i] * height).clamp(2.0, height),
                    decoration: BoxDecoration(
                      color: (i / values.length) <= progress
                          ? orange
                          : Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
