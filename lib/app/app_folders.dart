// app/app_folders.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppFolders {
  static const String rootName = 'MusicFoulderApp';

  static Future<Directory?> root() async {
    if (kIsWeb) return null;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$rootName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory?> dbDir() async {
    final r = await root();
    if (r == null) return null;
    final d = Directory('${r.path}/db');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<Directory?> artworkDir() async {
    final r = await root();
    if (r == null) return null;
    final d = Directory('${r.path}/artworks');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<Directory?> cacheDir() async {
    final r = await root();
    if (r == null) return null;
    final d = Directory('${r.path}/cache');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<Directory?> metaDir() async {
    final r = await root();
    if (r == null) return null;
    final d = Directory('${r.path}/meta');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }
}
