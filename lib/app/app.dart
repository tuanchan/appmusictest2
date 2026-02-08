// app/app.dart
import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';
import 'settings_controller.dart';
import 'settings_scope.dart';
import 'playback_controller.dart';
import 'playback_scope.dart';
import 'library_controller.dart';
import 'library_scope.dart';

class AppMusicVol2App extends StatelessWidget {
  final SettingsController settings;
  final PlaybackController playback;
  final LibraryController library;

  const AppMusicVol2App({
    super.key,
    required this.settings,
    required this.playback,
    required this.library,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: settings,
      child: LibraryScope(
        controller: library,
        child: PlaybackScope(
          controller: playback,
          child: AnimatedBuilder(
            animation: Listenable.merge([settings, playback, library]),
            builder: (context, _) {
              return MaterialApp(
                title: settings.appTitle,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: settings.themeMode,
                onGenerateRoute: AppRoutes.onGenerateRoute,
                initialRoute: AppRoutes.shell,
              );
            },
          ),
        ),
      ),
    );
  }
}
