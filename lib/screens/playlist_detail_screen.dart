// screens/playlist_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../widgets/blur_app_bar.dart';
import '../widgets/track_tile.dart';
import '../widgets/section_header.dart';
import '../app/routes.dart';
import '../app/playback_scope.dart';
import '../app/library_scope.dart';
import '../app/track_actions.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackScope.of(context);
    final library = LibraryScope.of(context);

    return AnimatedBuilder(
      animation: library,
      builder: (context, _) {
        final updated = library.playlists
            .firstWhere((p) => p.id == playlist.id, orElse: () => playlist);

        return Scaffold(
          appBar: BlurAppBar(title: updated.name),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 170),
            children: [
              SectionHeader(title: 'Danh sách bài (${updated.tracks.length})'),
              if (updated.tracks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Playlist trống.'),
                ),
              for (final t in updated.tracks)
                TrackTile(
                  track: t,
                  onTap: () {
                    playback.playTrack(t, queue: updated.tracks);
                    Navigator.of(context).pushNamed(
                      AppRoutes.nowPlaying,
                      arguments: t,
                    );
                  },
                  onMore: () => showTrackOptions(context, t),
                ),
            ],
          ),
        );
      },
    );
  }
}
