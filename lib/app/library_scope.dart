// app/library_scope.dart
import 'package:flutter/material.dart';
import 'library_controller.dart';

class LibraryScope extends InheritedNotifier<LibraryController> {
  const LibraryScope({
    super.key,
    required LibraryController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static LibraryController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LibraryScope>();
    assert(scope != null, 'LibraryScope not found in widget tree');
    return scope!.notifier!;
  }
}
