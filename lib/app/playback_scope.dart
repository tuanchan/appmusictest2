// app/playback_scope.dart
import 'package:flutter/material.dart';
import 'playback_controller.dart';

class PlaybackScope extends InheritedNotifier<PlaybackController> {
  const PlaybackScope({
    super.key,
    required PlaybackController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static PlaybackController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlaybackScope>();
    assert(scope != null, 'PlaybackScope not found in widget tree');
    return scope!.notifier!;
  }
}
