// models/track.dart
import 'dart:convert';

class Track {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String filePath;
  final String? artworkPath;

  /// UI-only: artworkColor tạo "ảnh" giả để nhìn đẹp trong list + now playing
  final int artworkColorArgb;

  /// UI-only: waveform data giả (0..1)
  final List<double> waveform;

  /// UI-only: liked
  final bool liked;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.filePath,
    required this.artworkColorArgb,
    required this.waveform,
    this.artworkPath,
    this.liked = false,
  });

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    Duration? duration,
    String? filePath,
    String? artworkPath,
    int? artworkColorArgb,
    List<double>? waveform,
    bool? liked,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      artworkPath: artworkPath ?? this.artworkPath,
      artworkColorArgb: artworkColorArgb ?? this.artworkColorArgb,
      waveform: waveform ?? this.waveform,
      liked: liked ?? this.liked,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration_ms': duration.inMilliseconds,
      'file_path': filePath,
      'artwork_path': artworkPath,
      'artwork_color_argb': artworkColorArgb,
      'waveform': jsonEncode(waveform),
      'liked': liked ? 1 : 0,
    };
  }

  static Track fromMap(Map<String, Object?> map) {
    final waveformRaw = map['waveform']?.toString() ?? '[]';
    List<double> waveform;
    try {
      final decoded = jsonDecode(waveformRaw);
      if (decoded is List) {
        waveform = decoded
            .map((e) => double.tryParse(e.toString()) ?? 0.0)
            .toList();
      } else {
        waveform = const <double>[];
      }
    } catch (_) {
      waveform = const <double>[];
    }

    return Track(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      duration: Duration(
        milliseconds: int.tryParse(map['duration_ms']?.toString() ?? '0') ?? 0,
      ),
      filePath: map['file_path']?.toString() ?? '',
      artworkPath: map['artwork_path']?.toString(),
      artworkColorArgb:
          int.tryParse(map['artwork_color_argb']?.toString() ?? '') ??
              0xFF111827,
      waveform: waveform,
      liked: (int.tryParse(map['liked']?.toString() ?? '0') ?? 0) == 1,
    );
  }
}
