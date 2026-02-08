// widgets/blur_app_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class BlurAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const BlurAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF0B0F14).withOpacity(0.65)
        : Colors.white.withOpacity(0.65);

    final fg = isDark ? Colors.white : Colors.black;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AppBar(
          title: Text(
            title,
            style: TextStyle(color: fg, fontWeight: FontWeight.w800),
          ),
          iconTheme: IconThemeData(color: fg),
          centerTitle: false,
          actions: actions,
          backgroundColor: bg,
        ),
      ),
    );
  }
}
