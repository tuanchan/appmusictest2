// screens/likes_screen.dart
import 'package:flutter/material.dart';
import '../widgets/blur_app_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/track_tile.dart';
import '../app/routes.dart';
import '../app/playback_scope.dart';
import '../app/library_scope.dart';
import '../app/track_actions.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = LibraryScope.of(context);
    final playback = PlaybackScope.of(context);

    return AnimatedBuilder(
      animation: library,
      builder: (context, _) {
        final liked = library.likedTracks;

        return Scaffold(
          appBar: const BlurAppBar(title: 'Đã thích'),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 170),
            children: [
              SectionHeader(title: 'Bài đã thả tim (${liked.length})'),
              if (liked.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có bài nào được thích.'),
                ),
              for (final t in liked)
                TrackTile(
                  track: t,
                  onTap: () {
                    playback.playTrack(t, queue: liked);
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
