// services/library_store.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryStore {
  LibraryStore._(this._prefs);

  static const _deletedTrackKey = 'deletedTrackIds';
  static const _deletedPlaylistKey = 'deletedPlaylistIds';
  static const _artworkMapKey = 'trackArtworkPathById';

  final SharedPreferences _prefs;

  final Set<String> _deletedTrackIds = <String>{};
  final Set<String> _deletedPlaylistIds = <String>{};
  final Map<String, String> _artworkMap = <String, String>{};

  Set<String> get deletedTrackIds => Set<String>.from(_deletedTrackIds);
  Set<String> get deletedPlaylistIds => Set<String>.from(_deletedPlaylistIds);
  Map<String, String> get artworkMap => Map<String, String>.from(_artworkMap);

  static Future<LibraryStore> init() async {
    final prefs = await SharedPreferences.getInstance();
    final store = LibraryStore._(prefs);
    await store._load();
    return store;
  }

  Future<void> _load() async {
    _deletedTrackIds
      ..clear()
      ..addAll(_prefs.getStringList(_deletedTrackKey) ?? const <String>[]);
    _deletedPlaylistIds
      ..clear()
      ..addAll(_prefs.getStringList(_deletedPlaylistKey) ?? const <String>[]);

    final rawMap = _prefs.getString(_artworkMapKey);
    if (rawMap != null && rawMap.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMap);
        if (decoded is Map) {
          _artworkMap
            ..clear()
            ..addAll(
              decoded.map(
                (key, value) => MapEntry(
                  key.toString(),
                  value.toString(),
                ),
              ),
            );
        }
      } catch (_) {
        _artworkMap.clear();
      }
    }
  }

  Future<void> setDeletedTrack(String trackId, bool deleted) async {
    if (deleted) {
      _deletedTrackIds.add(trackId);
    } else {
      _deletedTrackIds.remove(trackId);
    }
    await _prefs.setStringList(
      _deletedTrackKey,
      _deletedTrackIds.toList(),
    );
  }

  Future<void> setDeletedPlaylist(String playlistId, bool deleted) async {
    if (deleted) {
      _deletedPlaylistIds.add(playlistId);
    } else {
      _deletedPlaylistIds.remove(playlistId);
    }
    await _prefs.setStringList(
      _deletedPlaylistKey,
      _deletedPlaylistIds.toList(),
    );
  }

  Future<void> setArtworkPath(String trackId, String? path) async {
    if (path == null || path.trim().isEmpty) {
      _artworkMap.remove(trackId);
    } else {
      _artworkMap[trackId] = path;
    }
    await _prefs.setString(_artworkMapKey, jsonEncode(_artworkMap));
  }
}
