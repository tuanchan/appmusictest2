// data/library_repository.dart
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../app/app_folders.dart';
import '../models/playlist.dart';
import '../models/track.dart';

class LibraryRepository {
  Database? _db;

  final Map<String, Track> _memTracks = <String, Track>{};
  final Map<String, Playlist> _memPlaylists = <String, Playlist>{};
  final Map<String, List<String>> _memPlaylistTracks =
      <String, List<String>>{};

  bool get isWeb => kIsWeb;

  Future<void> init() async {
    if (isWeb) return;
    final dbDir = await AppFolders.dbDir();
    if (dbDir == null) return;
    final path = p.join(dbDir.path, 'library.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE tracks('
          'id TEXT PRIMARY KEY,'
          'title TEXT,'
          'artist TEXT,'
          'duration_ms INTEGER,'
          'file_path TEXT,'
          'artwork_path TEXT,'
          'artwork_color_argb INTEGER,'
          'waveform TEXT,'
          'liked INTEGER'
          ')',
        );
        await db.execute(
          'CREATE TABLE playlists('
          'id TEXT PRIMARY KEY,'
          'name TEXT,'
          'subtitle TEXT'
          ')',
        );
        await db.execute(
          'CREATE TABLE playlist_tracks('
          'playlist_id TEXT,'
          'track_id TEXT,'
          'position INTEGER,'
          'PRIMARY KEY (playlist_id, track_id)'
          ')',
        );
      },
    );
  }

  Future<void> close() async {
    if (isWeb) return;
    await _db?.close();
    _db = null;
  }

  Future<List<Playlist>> fetchPlaylists() async {
    if (isWeb) {
      return _memPlaylists.values
          .map((p) => p.copyWith(tracks: _tracksForPlaylist(p.id)))
          .toList();
    }

    final db = _db;
    if (db == null) return <Playlist>[];
    final rows = await db.query('playlists');
    final playlists = <Playlist>[];
    for (final row in rows) {
      final playlist = Playlist.fromMap(row);
      final tracks = await fetchTracksForPlaylist(playlist.id);
      playlists.add(playlist.copyWith(tracks: tracks));
    }
    return playlists;
  }

  Future<List<Track>> fetchTracksForPlaylist(String playlistId) async {
    if (isWeb) return _tracksForPlaylist(playlistId);
    final db = _db;
    if (db == null) return <Track>[];
    final rows = await db.rawQuery(
      'SELECT t.* FROM tracks t '
      'INNER JOIN playlist_tracks pt ON t.id = pt.track_id '
      'WHERE pt.playlist_id = ? ORDER BY pt.position ASC',
      [playlistId],
    );
    return rows.map(Track.fromMap).toList();
  }

  Future<List<Track>> fetchAllTracks() async {
    if (isWeb) return _memTracks.values.toList();
    final db = _db;
    if (db == null) return <Track>[];
    final rows = await db.query('tracks');
    return rows.map(Track.fromMap).toList();
  }

  Future<List<Track>> fetchLikedTracks() async {
    if (isWeb) {
      return _memTracks.values.where((t) => t.liked).toList();
    }
    final db = _db;
    if (db == null) return <Track>[];
    final rows = await db.query('tracks', where: 'liked = 1');
    return rows.map(Track.fromMap).toList();
  }

  Future<Track?> getTrack(String id) async {
    if (isWeb) return _memTracks[id];
    final db = _db;
    if (db == null) return null;
    final rows = await db.query('tracks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Track.fromMap(rows.first);
  }

  Future<void> upsertTrack(Track track) async {
    if (isWeb) {
      _memTracks[track.id] = track;
      return;
    }
    final db = _db;
    if (db == null) return;
    await db.insert(
      'tracks',
      track.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> createPlaylist(Playlist playlist) async {
    if (isWeb) {
      _memPlaylists[playlist.id] = playlist.copyWith(tracks: []);
      _memPlaylistTracks.putIfAbsent(playlist.id, () => <String>[]);
      return;
    }
    final db = _db;
    if (db == null) return;
    await db.insert(
      'playlists',
      playlist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    if (isWeb) {
      final list = _memPlaylistTracks.putIfAbsent(playlistId, () => <String>[]);
      if (!list.contains(trackId)) list.add(trackId);
      return;
    }
    final db = _db;
    if (db == null) return;
    final currentCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?',
        [playlistId],
      ),
    );
    await db.insert(
      'playlist_tracks',
      {
        'playlist_id': playlistId,
        'track_id': trackId,
        'position': currentCount ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> setLiked(String trackId, bool liked) async {
    if (isWeb) {
      final track = _memTracks[trackId];
      if (track != null) {
        _memTracks[trackId] = track.copyWith(liked: liked);
      }
      return;
    }
    final db = _db;
    if (db == null) return;
    await db.update(
      'tracks',
      {'liked': liked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  Future<void> setArtworkPath(String trackId, String? artworkPath) async {
    if (isWeb) {
      final track = _memTracks[trackId];
      if (track != null) {
        _memTracks[trackId] = track.copyWith(artworkPath: artworkPath);
      }
      return;
    }
    final db = _db;
    if (db == null) return;
    await db.update(
      'tracks',
      {'artwork_path': artworkPath},
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  Future<Playlist?> findPlaylistByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    if (isWeb) {
      for (final playlist in _memPlaylists.values) {
        if (playlist.name == trimmed) return playlist;
      }
      return null;
    }

    final db = _db;
    if (db == null) return null;
    final rows =
        await db.query('playlists', where: 'name = ?', whereArgs: [trimmed]);
    if (rows.isEmpty) return null;
    final playlist = Playlist.fromMap(rows.first);
    final tracks = await fetchTracksForPlaylist(playlist.id);
    return playlist.copyWith(tracks: tracks);
  }

  List<Track> _tracksForPlaylist(String playlistId) {
    final ids = _memPlaylistTracks[playlistId] ?? <String>[];
    return ids
        .map((id) => _memTracks[id])
        .whereType<Track>()
        .toList();
  }
}
