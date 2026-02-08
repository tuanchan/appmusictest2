// screens/now_playing_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../widgets/waveform_bar.dart';
import '../models/track.dart';
import '../app/library_scope.dart';
import '../app/playback_scope.dart';
import '../app/track_actions.dart';

class NowPlayingScreen extends StatelessWidget {
  final Track? track;
  const NowPlayingScreen({super.key, this.track});

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final orange = AppTheme.soundCloudOrange;
    final playback = PlaybackScope.of(context);
    final library = LibraryScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([playback, library]),
      builder: (context, _) {
        final fallback = Track(
          id: '',
          title: 'Chưa có bài nào',
          artist: 'Hãy import mp3 để bắt đầu',
          duration: Duration.zero,
          filePath: '',
          artworkColorArgb: 0xFF111827,
          waveform: const <double>[],
        );
        final t = track ?? playback.currentTrack ?? fallback;
        final liked = t.id.isNotEmpty && library.isLiked(t.id);
        final playbackDuration = playback.duration.inMilliseconds == 0
            ? t.duration
            : playback.duration;
        final progress = playbackDuration.inMilliseconds == 0
            ? 0.0
            : (playback.position.inMilliseconds /
                    playbackDuration.inMilliseconds)
                .clamp(0.0, 1.0);

        final artworkPath = library.artworkPathForTrack(t);
        final hasArtwork = artworkPath != null && artworkPath.trim().isNotEmpty;

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(t.artworkColorArgb).withOpacity(0.95),
                        const Color(0xFF111827),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                    child: Container(color: Colors.black.withOpacity(0.10)),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            color: Colors.white,
                          ),
                          const Expanded(
                            child: Text(
                              'Đang phát',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: t.id.isEmpty
                                ? null
                                : () => showTrackOptions(context, t),
                            icon: const Icon(Icons.more_horiz_rounded),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: [
                                orange,
                                Color(t.artworkColorArgb),
                                Colors.black.withOpacity(0.25),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                                color: Colors.black.withOpacity(0.35),
                              ),
                            ],
                          ),
                          child: hasArtwork && !kIsWeb
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.file(
                                    File(artworkPath!),
                                    key: ValueKey(artworkPath),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.graphic_eq_rounded,
                                      size: 86, color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  t.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.72),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: t.id.isEmpty
                                ? null
                                : () => library.toggleLike(t.id),
                            icon: Icon(
                              liked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: liked
                                  ? orange
                                  : (isDark
                                      ? Colors.white54
                                      : Colors.white.withOpacity(0.85)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: WaveformBar(
                        values: t.waveform,
                        height: 40,
                        progress: progress,
                        onSeek: (p) => playback.seek(
                          Duration(
                            milliseconds:
                                (playbackDuration.inMilliseconds * p).round(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(playback.position),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.72))),
                          Text(_fmt(playbackDuration),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.72))),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            color: Colors.white.withOpacity(0.10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: playback.toggleAutoplay,
                                  icon: const Icon(Icons.shuffle_rounded),
                                  color: playback.isAutoplay
                                      ? orange
                                      : Colors.white.withOpacity(0.92),
                                ),
                                IconButton(
                                  onPressed: playback.skipPrevious,
                                  icon: const Icon(Icons.skip_previous_rounded),
                                  iconSize: 34,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: orange,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: IconButton(
                                    onPressed: playback.togglePlayPause,
                                    icon: Icon(
                                      playback.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                    iconSize: 38,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: playback.skipNext,
                                  icon: const Icon(Icons.skip_next_rounded),
                                  iconSize: 34,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                                IconButton(
                                  onPressed: playback.toggleLoop,
                                  icon: const Icon(Icons.repeat_rounded),
                                  color: playback.isLoop
                                      ? orange
                                      : Colors.white.withOpacity(0.92),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
