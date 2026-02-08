// screens/shell_screen.dart
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'library_screen.dart';
import 'likes_screen.dart';
import 'now_playing_screen.dart';
import 'settings_screen.dart';

import '../widgets/mini_player.dart';
import '../app/playback_scope.dart';
import '../app/routes.dart';
import '../app/library_scope.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const double _navHeight = 66;
  static const double _sidePad = 12;
  static const double _bottomPad = 12;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackScope.of(context);
    final library = LibraryScope.of(context);
    final t = playback.currentTrack;

    final pages = [
      const HomeScreen(),
      const LibraryScreen(),
      const LikesScreen(),
      NowPlayingScreen(track: t),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: pages,
        ),
      ),

      // ✅ Fix: dùng Stack để mini player luôn nằm "trên" NavigationBar, không bị đè
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: _navHeight +
              _bottomPad +
              (t != null && _index != 3 ? 86 + _gap : 0),
          child: Stack(
            children: [
              // NavigationBar luôn ở đáy
              Positioned(
                left: _sidePad,
                right: _sidePad,
                bottom: _bottomPad,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: NavigationBar(
                    height: _navHeight,
                    selectedIndex: _index,
                    onDestinationSelected: (v) => setState(() => _index = v),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.folder_outlined),
                        selectedIcon: Icon(Icons.folder),
                        label: 'Thư mục',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.favorite_border),
                        selectedIcon: Icon(Icons.favorite),
                        label: 'Đã thích',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.music_note_outlined),
                        selectedIcon: Icon(Icons.music_note),
                        label: 'Player',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: 'Cài đặt',
                      ),
                    ],
                  ),
                ),
              ),

              // MiniPlayer nổi phía trên NavigationBar
              if (_index != 3 && t != null)
                Positioned(
                  left: _sidePad,
                  right: _sidePad,
                  bottom: _bottomPad + _navHeight + _gap,
                  child: MiniPlayer(
                    track: t,
                    liked: library.isLiked(t.id),
                    isPlaying: playback.isPlaying,
                    onTap: () {
                      playback.playTrack(t, queue: playback.queue);
                      Navigator.of(context).pushNamed(
                        AppRoutes.nowPlaying,
                        arguments: t,
                      );
                    },
                    onLike: () => library.toggleLike(t.id),
                    onPlayPause: playback.togglePlayPause,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
