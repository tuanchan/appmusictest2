// models/playlist.dart
import 'track.dart';

class Playlist {
  final String id;
  final String name;

  /// mô phỏng "thư mục" / "thể loại"
  final String subtitle;

  final List<Track> tracks;

  const Playlist({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.tracks,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? subtitle,
    List<Track>? tracks,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      tracks: tracks ?? this.tracks,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
    };
  }

  static Playlist fromMap(Map<String, Object?> map, {List<Track>? tracks}) {
    return Playlist(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      tracks: tracks ?? const <Track>[],
    );
  }
}
