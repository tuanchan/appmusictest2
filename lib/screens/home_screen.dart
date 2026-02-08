// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/blur_app_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/track_tile.dart';
import '../app/settings_scope.dart';
import '../app/routes.dart';
import '../app/playback_scope.dart';
import '../app/library_scope.dart';
import '../app/track_actions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = LibraryScope.of(context);
    final playback = PlaybackScope.of(context);
    final title = SettingsScope.of(context).appTitle;

    return AnimatedBuilder(
      animation: library,
      builder: (context, _) {
        final recent = library.recentTracks(limit: 6);

        return Scaffold(
          appBar: BlurAppBar(title: title),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              const SectionHeader(title: 'Gần đây'),
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có bài nào. Hãy import mp3 để bắt đầu.'),
                ),
              for (final t in recent)
                TrackTile(
                  track: t,
                  onTap: () {
                    playback.playTrack(t, queue: recent);
                    Navigator.of(context).pushNamed(
                      AppRoutes.nowPlaying,
                      arguments: t,
                    );
                  },
                  onMore: () => showTrackOptions(context, t),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
