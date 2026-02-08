// app/routes.dart
import 'package:flutter/material.dart';

import '../screens/shell_screen.dart';
import '../screens/playlist_detail_screen.dart';
import '../screens/now_playing_screen.dart';

import '../models/playlist.dart';
import '../models/track.dart';

class AppRoutes {
  static const shell = '/';
  static const playlistDetail = '/playlist';
  static const nowPlaying = '/now-playing';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case shell:
        return MaterialPageRoute(builder: (_) => const ShellScreen());

      case playlistDetail:
        {
          final args = settings.arguments;
          if (args is! Playlist) {
            return MaterialPageRoute(builder: (_) => const ShellScreen());
          }
          return MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlist: args),
          );
        }

      case nowPlaying:
        {
          final args = settings.arguments;
          final track = (args is Track) ? args : null;
          return MaterialPageRoute(
            builder: (_) => NowPlayingScreen(track: track),
          );
        }

      default:
        return MaterialPageRoute(builder: (_) => const ShellScreen());
    }
  }
}
