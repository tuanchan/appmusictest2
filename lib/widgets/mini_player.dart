// widgets/mini_player.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/track.dart';

class MiniPlayer extends StatelessWidget {
  final Track track;
  final bool liked;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onPlayPause;

  const MiniPlayer({
    super.key,
    required this.track,
    required this.liked,
    required this.isPlaying,
    this.onTap,
    this.onLike,
    this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final orange = AppTheme.soundCloudOrange;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF111827).withOpacity(0.78)
        : Colors.white.withOpacity(0.78);

    final titleColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : Colors.black54;

    final artworkPath = track.artworkPath;
    final hasArtwork = artworkPath != null && artworkPath.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: bg,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(14),
                        image: hasArtwork && !kIsWeb
                            ? DecorationImage(
                                image: FileImage(File(artworkPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: hasArtwork
                          ? null
                          : const Icon(Icons.graphic_eq_rounded,
                              color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: subColor),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(999),
                      child: Icon(
                        liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: liked
                            ? orange
                            : (isDark ? Colors.white38 : Colors.black26),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: onPlayPause,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: orange.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: orange,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
