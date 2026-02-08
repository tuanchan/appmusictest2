// app/playback_controller.dart
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import 'audio_handler.dart';

class PlaybackController extends ChangeNotifier {
  AppAudioHandler? _handler;
  AudioPlayer? _player;

  Track? _current;
  List<Track> _queue = const <Track>[];
  Duration _position = Duration.zero;
  bool _playing = false;

  StreamSubscription<PlaybackState>? _playbackSub;
  StreamSubscription<MediaItem?>? _mediaSub;
  StreamSubscription<Duration>? _positionSub;

  Track? get currentTrack => _current;
  List<Track> get queue => _queue;
  Duration get position => _position;
  bool get isPlaying => _playing;

  Future<void> init() async {
    if (kIsWeb) {
      _player = AudioPlayer();
      _positionSub = _player!.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      });
      _player!.playerStateStream.listen((state) {
        _playing = state.playing;
        notifyListeners();
      });
      return;
    }

    _handler = await AudioService.init(
      builder: () => AppAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'appmusicvol2.playback',
        androidNotificationChannelName: 'Playback',
        androidNotificationOngoing: true,
      ),
    );

    _playbackSub = _handler!.playbackState.listen((state) {
      _playing = state.playing;
      _position = state.updatePosition;
      notifyListeners();
    });

    _mediaSub = _handler!.mediaItem.listen((item) {
      if (item == null) return;
      final match = _queue.firstWhere(
        (t) => t.id == item.id,
        orElse: () =>
            _current ??
            Track(
              id: item.id,
              title: item.title,
              artist: item.artist ?? '',
              duration: item.duration ?? Duration.zero,
              filePath: item.extras?['filePath']?.toString() ?? '',
              artworkColorArgb: 0xFF111827,
              waveform: const <double>[],
            ),
      );
      _current = match;
      notifyListeners();
    });
  }

  Future<void> disposeController() async {
    await _playbackSub?.cancel();
    await _mediaSub?.cancel();
    await _positionSub?.cancel();
    await _handler?.stop();

    await _player?.dispose();
  }

  Future<void> setQueue(List<Track> tracks) async {
    _queue = tracks;
    if (tracks.isEmpty) {
      _current = null;
      notifyListeners();
      return;
    }

    if (kIsWeb) {
      final first = tracks.first;
      _current = first;
      await _player?.setFilePath(first.filePath);
      notifyListeners();
      return;
    }

    await _handler?.setQueue(tracks);
    _current = tracks.first;
    notifyListeners();
  }

  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    if (queue != null) {
      await setQueue(queue);
    } else if (_queue.isEmpty) {
      await setQueue([track]);
    }

    _current = track;
    notifyListeners();

    if (kIsWeb) {
      await _player?.setFilePath(track.filePath);
      await _player?.play();
      return;
    }

    await _handler?.playFromMediaId(track.id);
  }

  Future<void> togglePlayPause() async {
    if (kIsWeb) {
      if (_player == null) return;
      if (_player!.playing) {
        await _player!.pause();
      } else {
        await _player!.play();
      }
      return;
    }

    if (_playing) {
      await _handler?.pause();
    } else {
      await _handler?.play();
    }
  }

  Future<void> seek(Duration position) async {
    if (kIsWeb) {
      await _player?.seek(position);
      return;
    }
    await _handler?.seek(position);
  }

  Future<void> skipNext() async {
    if (kIsWeb) {
      await _player?.seekToNext();
      return;
    }
    await _handler?.skipToNext();
  }

  Future<void> skipPrevious() async {
    if (kIsWeb) {
      await _player?.seekToPrevious();
      return;
    }
    await _handler?.skipToPrevious();
  }
}
