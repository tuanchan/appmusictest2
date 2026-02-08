// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/app_folders.dart';
import 'app/settings_controller.dart';
import 'app/playback_controller.dart';
import 'app/library_controller.dart';
import 'data/library_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await AppFolders.root();
    await AppFolders.dbDir();
    await AppFolders.artworkDir();
    await AppFolders.cacheDir();
  }

  final settings = SettingsController();
  await settings.load();

  final repository = LibraryRepository();
  await repository.init();

  final library = LibraryController(repository: repository);
  await library.load();

  final playback = PlaybackController();
  await playback.init();

  runApp(AppMusicVol2App(
    settings: settings,
    playback: playback,
    library: library,
  ));
}
