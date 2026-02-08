// app/library_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:just_audio/just_audio.dart';
import '../data/library_repository.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import 'app_folders.dart';

class LibraryController extends ChangeNotifier {
  final LibraryRepository repository;
  final AudioPlayer _probePlayer = AudioPlayer();

  List<Playlist> _playlists = const <Playlist>[];
  List<Track> _liked = const <Track>[];
  bool _loaded = false;

  LibraryController({required this.repository});

  List<Playlist> get playlists => _playlists;
  List<Track> get likedTracks => _liked;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _playlists = await repository.fetchPlaylists();
    _liked = await repository.fetchLikedTracks();
    _loaded = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _playlists = await repository.fetchPlaylists();
    _liked = await repository.fetchLikedTracks();
    notifyListeners();
  }

  Track? getTrackById(String id) {
    for (final playlist in _playlists) {
      for (final track in playlist.tracks) {
        if (track.id == id) return track;
      }
    }
    return null;
  }

  List<Track> recentTracks({int limit = 6}) {
    final all = _playlists.expand((p) => p.tracks).toList();
    return all.take(limit).toList();
  }

  bool isLiked(String trackId) {
    return _liked.any((t) => t.id == trackId);
  }

  Future<void> toggleLike(String trackId) async {
    final current = isLiked(trackId);
    await repository.setLiked(trackId, !current);
    await refresh();
  }

  Future<void> createPlaylist(BuildContext context) async {
    final name = await _promptText(context, 'Tạo playlist', 'Nhập tên playlist');
    if (name == null) return;

    final id = _idFromText('$name-${DateTime.now().microsecondsSinceEpoch}');
    final playlist = Playlist(
      id: id,
      name: name,
      subtitle: 'Playlist',
      tracks: const <Track>[],
    );
    await repository.createPlaylist(playlist);
    await refresh();
  }

  Future<void> addTrackToPlaylist(
    BuildContext context, {
    required Track track,
  }) async {
    if (_playlists.isEmpty) {
      _showMessage(context, 'Chưa có playlist để thêm.');
      return;
    }

    final playlistId = await _pickPlaylistId(context);
    if (playlistId == null) return;

    await repository.addTrackToPlaylist(playlistId, track.id);
    await refresh();
  }

  Future<void> showImportOptions(BuildContext context) async {
    if (kIsWeb) {
      _showMessage(context, 'Web không hỗ trợ import mp3.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.library_music_rounded),
                title: const Text('Chọn file mp3'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await importFromFiles(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_rounded),
                title: const Text('Chọn folder (nếu iOS cho phép)'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await importFromFolder(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> importFromFiles(BuildContext context) async {
    if (kIsWeb) {
      _showMessage(context, 'Web không hỗ trợ import mp3.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['mp3'],
    );
    if (result == null) return;

    final paths = result.paths.whereType<String>().toList();
    if (paths.isEmpty) return;

    final playlist = await _getOrCreatePlaylist('Downloads');
    await _importPaths(paths, playlistId: playlist.id);
    await refresh();
  }

  Future<void> importFromFolder(BuildContext context) async {
    if (kIsWeb) {
      _showMessage(context, 'Web không hỗ trợ import mp3.');
      return;
    }

    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null || dirPath.trim().isEmpty) return;

    final root = Directory(dirPath);
    final folderMap = <String, List<String>>{};

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.mp3') continue;
      final folder = p.dirname(entity.path);
      folderMap.putIfAbsent(folder, () => <String>[]).add(entity.path);
    }

    for (final entry in folderMap.entries) {
      final folderName = p.basename(entry.key);
      if (folderName.trim().isEmpty) continue;
      final playlist = await _getOrCreatePlaylist(folderName);
      await _importPaths(entry.value, playlistId: playlist.id);
    }

    await refresh();
  }

  Future<void> setArtwork(BuildContext context, Track track) async {
    if (kIsWeb) {
      _showMessage(context, 'Web không hỗ trợ chọn ảnh.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null) return;

    final path = result.files.single.path;
    if (path == null || path.isEmpty) return;

    final artworks = await AppFolders.artworkDir();
    if (artworks == null) return;

    final destPath = p.join(artworks.path, '${track.id}.jpg');
    await File(path).copy(destPath);
    await repository.setArtworkPath(track.id, destPath);
    await refresh();
  }

  Future<void> clearArtwork(Track track) async {
    final artworkPath = track.artworkPath;
    if (!kIsWeb && artworkPath != null && artworkPath.isNotEmpty) {
      try {
        final file = File(artworkPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // ignore
      }
    }
    await repository.setArtworkPath(track.id, null);
    await refresh();
  }

  Future<void> disposeController() async {
    await _probePlayer.dispose();
  }

  Future<void> _importPaths(
    List<String> paths, {
    required String playlistId,
  }) async {
    for (final path in paths) {
      if (path.trim().isEmpty) continue;
      final id = _idFromText(path);
      final title = p.basenameWithoutExtension(path);
      final duration = await _readDuration(path);
      final track = Track(
        id: id,
        title: title,
        artist: 'Unknown Artist',
        duration: duration,
        filePath: path,
        artworkColorArgb: _colorFromSeed(id),
        waveform: _waveformFromSeed(id),
        artworkPath: null,
        liked: false,
      );

      await repository.upsertTrack(track);
      await repository.addTrackToPlaylist(playlistId, track.id);
    }
  }

  Future<Duration> _readDuration(String path) async {
    try {
      await _probePlayer.setFilePath(path);
      final duration = _probePlayer.duration;
      if (duration != null) return duration;
    } catch (_) {
      // ignore
    }
    return Duration.zero;
  }

  Future<Playlist> _getOrCreatePlaylist(String name) async {
    final existing = await repository.findPlaylistByName(name);
    if (existing != null) return existing;

    final playlist = Playlist(
      id: _idFromText('$name-${DateTime.now().microsecondsSinceEpoch}'),
      name: name,
      subtitle: 'Thư mục',
      tracks: const <Track>[],
    );
    await repository.createPlaylist(playlist);
    return playlist;
  }

  Future<String?> _promptText(
    BuildContext context,
    String title,
    String hint,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
    final trimmed = result?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<String?> _pickPlaylistId(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Chọn playlist'),
          children: [
            for (final playlist in _playlists)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(playlist.id),
                child: Text(playlist.name),
              ),
          ],
        );
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _idFromText(String input) {
    final bytes = utf8.encode(input);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  int _colorFromSeed(String seed) {
    final hash = seed.hashCode;
    final r = 0x30 + (hash & 0x7F);
    final g = 0x30 + ((hash >> 8) & 0x7F);
    final b = 0x30 + ((hash >> 16) & 0x7F);
    return 0xFF000000 | (r << 16) | (g << 8) | b;
  }

  List<double> _waveformFromSeed(String seed) {
    final out = <double>[];
    var x = seed.hashCode;
    for (var i = 0; i < 48; i++) {
      x = (x * 1103515245 + 12345) & 0x7fffffff;
      final v = (x % 1000) / 1000.0;
      out.add((v * 0.85 + 0.15).clamp(0.12, 1.0));
    }
    return out;
  }
}
