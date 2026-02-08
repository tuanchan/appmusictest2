// widgets/track_tile.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../app/theme.dart';
import 'waveform_bar.dart';
import '../app/library_scope.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.onMore,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bg = Color(track.artworkColorArgb);
    final orange = AppTheme.soundCloudOrange;
    final library = LibraryScope.of(context);
    final liked = library.isLiked(track.id);
    final artworkPath = track.artworkPath;
    final hasArtwork = artworkPath != null && artworkPath.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bg,
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
                  : Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white.withOpacity(0.95),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _fmt(track.duration),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // ✅ like thật (persist)
                      InkWell(
                        onTap: () => library.toggleLike(track.id),
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: liked ? orange : Colors.black26,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  WaveformBar(
                      values: track.waveform, height: 28, progress: 0.28),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
