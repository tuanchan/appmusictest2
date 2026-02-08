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
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _isLoop = false;
  bool _isAutoplay = true;
  bool _isDemoMode = false;

  StreamSubscription<PlaybackState>? _playbackSub;
  StreamSubscription<MediaItem?>? _mediaSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ProcessingState>? _processingSub;
  Timer? _demoTimer;

  Track? get currentTrack => _current;
  List<Track> get queue => _queue;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _playing;
  bool get isLoop => _isLoop;
  bool get isAutoplay => _isAutoplay;

  double get progress {
    final totalMs = _duration.inMilliseconds;
    if (totalMs == 0) return 0.0;
    return (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);
  }

  Future<void> init() async {
    if (kIsWeb) {
      _player = AudioPlayer();
      _positionSub = _player!.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      });
      _durationSub = _player!.durationStream.listen((dur) {
        if (dur == null) return;
        _duration = dur;
        notifyListeners();
      });
      _player!.playerStateStream.listen((state) {
        _playing = state.playing;
        notifyListeners();
      });
      _processingSub = _player!.processingStateStream.listen(_onComplete);
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
      _duration = item.duration ?? _duration;
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
              artworkPath: item.extras?['artworkPath']?.toString(),
            ),
      );
      _current = match;
      notifyListeners();
    });

    _durationSub = _handler!.player.durationStream.listen((dur) {
      if (dur == null) return;
      _duration = dur;
      notifyListeners();
    });

    _processingSub =
        _handler!.player.processingStateStream.listen(_onComplete);
  }

  Future<void> disposeController() async {
    await _playbackSub?.cancel();
    await _mediaSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _processingSub?.cancel();
    _stopDemoTicker();
    await _handler?.stop();
    await _player?.dispose();
  }

  Future<void> setQueue(List<Track> tracks) async {
    _queue = tracks;
    if (tracks.isEmpty) {
      _current = null;
      _duration = Duration.zero;
      _position = Duration.zero;
      notifyListeners();
      return;
    }

    _current = tracks.first;
    _duration = _current!.duration;
    _position = Duration.zero;
    notifyListeners();

    if (kIsWeb) {
      try {
        await _player?.setFilePath(_current!.filePath);
        _exitDemoMode();
      } catch (_) {
        _enterDemoMode(_current!);
      }
      return;
    }

    try {
      await _handler?.setQueue(tracks);
      _exitDemoMode();
    } catch (_) {
      _enterDemoMode(_current!);
    }
  }

  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    if (queue != null) {
      await setQueue(queue);
    } else if (_queue.isEmpty) {
      await setQueue([track]);
    }

    _current = track;
    _duration = track.duration;
    _position = Duration.zero;
    notifyListeners();

    if (track.filePath.trim().isEmpty) {
      _enterDemoMode(track);
      _startDemoTicker();
      return;
    }

    if (kIsWeb) {
      try {
        await _player?.setFilePath(track.filePath);
        await _player?.play();
        _exitDemoMode();
      } catch (_) {
        _enterDemoMode(track);
        _startDemoTicker();
      }
      return;
    }

    try {
      await _handler?.playFromMediaId(track.id);
      _exitDemoMode();
    } catch (_) {
      _enterDemoMode(track);
      _startDemoTicker();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isDemoMode) {
      if (_playing) {
        _playing = false;
        _stopDemoTicker();
      } else {
        _playing = true;
        _startDemoTicker();
      }
      notifyListeners();
      return;
    }

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
    final target = _clampPosition(position);
    if (_isDemoMode) {
      _position = target;
      notifyListeners();
      return;
    }

    if (kIsWeb) {
      try {
        await _player?.seek(target);
      } catch (_) {
        _enterDemoMode(_current);
      }
      return;
    }

    try {
      await _handler?.seek(target);
    } catch (_) {
      _enterDemoMode(_current);
    }
  }

  Future<void> skipNext() async {
    if (_isDemoMode) {
      _skipDemo(1);
      return;
    }
    if (kIsWeb) {
      await _player?.seekToNext();
      return;
    }
    await _handler?.skipToNext();
  }

  Future<void> skipPrevious() async {
    if (_isDemoMode) {
      _skipDemo(-1);
      return;
    }
    if (kIsWeb) {
      await _player?.seekToPrevious();
      return;
    }
    await _handler?.skipToPrevious();
  }

  Future<void> toggleLoop() async {
    _isLoop = !_isLoop;
    if (!_isDemoMode) {
      final mode = _isLoop ? LoopMode.one : LoopMode.off;
      if (kIsWeb) {
        await _player?.setLoopMode(mode);
      } else {
        await _handler?.player.setLoopMode(mode);
      }
    }
    notifyListeners();
  }

  void toggleAutoplay() {
    _isAutoplay = !_isAutoplay;
    notifyListeners();
  }

  Future<void> updateArtwork(String trackId, String? path) async {
    if (_current?.id != trackId) return;
    _current = _current?.copyWith(artworkPath: path);
    notifyListeners();

    if (kIsWeb) return;
    final item = _handler?.mediaItem.value;
    if (item == null) return;
    final updated = item.copyWith(
      artUri: (path != null && path.trim().isNotEmpty)
          ? Uri.file(path)
          : null,
      extras: {
        ...?item.extras,
        'artworkPath': path,
      },
    );
    _handler?.mediaItem.add(updated);
  }

  void _enterDemoMode(Track? track) {
    _isDemoMode = true;
    _playing = true;
    if (track != null) {
      _duration = track.duration.inMilliseconds == 0
          ? const Duration(minutes: 3)
          : track.duration;
      _position = _clampPosition(_position);
    }
    notifyListeners();
  }

  void _exitDemoMode() {
    if (_isDemoMode) {
      _isDemoMode = false;
      _stopDemoTicker();
    }
  }

  void _startDemoTicker() {
    _demoTimer?.cancel();
    if (!_playing) return;
    _demoTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_playing) return;
      final next = _position + const Duration(milliseconds: 250);
      if (next >= _duration && _duration != Duration.zero) {
        if (_isLoop) {
          _position = Duration.zero;
        } else if (_isAutoplay) {
          _skipDemo(1);
          return;
        } else {
          _position = _duration;
          _playing = false;
          _stopDemoTicker();
        }
      } else {
        _position = next;
      }
      notifyListeners();
    });
  }

  void _stopDemoTicker() {
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  void _skipDemo(int step) {
    if (_queue.isEmpty) return;
    final index = _queue.indexWhere((t) => t.id == _current?.id);
    final nextIndex = index == -1
        ? 0
        : (index + step).clamp(0, _queue.length - 1);
    _current = _queue[nextIndex];
    _duration = _current!.duration.inMilliseconds == 0
        ? const Duration(minutes: 3)
        : _current!.duration;
    _position = Duration.zero;
    _playing = true;
    _startDemoTicker();
    notifyListeners();
  }

  Duration _clampPosition(Duration position) {
    if (_duration == Duration.zero) return position;
    if (position < Duration.zero) return Duration.zero;
    if (position > _duration) return _duration;
    return position;
  }

  void _onComplete(ProcessingState state) {
    if (state != ProcessingState.completed) return;
    if (_isLoop) {
      seek(Duration.zero);
      if (!_playing) togglePlayPause();
      return;
    }
    if (_isAutoplay) {
      skipNext();
    }
  }
}
