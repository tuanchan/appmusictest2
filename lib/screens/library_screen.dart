// screens/library_screen.dart
import 'package:flutter/material.dart';
import '../widgets/blur_app_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/playlist_card.dart';
import '../app/routes.dart';
import '../app/library_scope.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = LibraryScope.of(context);

    return AnimatedBuilder(
      animation: library,
      builder: (context, _) {
        final playlists = library.playlists;

        return Scaffold(
          appBar: BlurAppBar(
            title: 'Thư mục & Playlist',
            actions: [
              IconButton(
                onPressed: () => library.createPlaylist(context),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Thêm playlist',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 170),
            children: [
              SectionHeader(
                title: 'Danh sách từ thư mục',
                actionText: 'Import',
                onAction: () => library.showImportOptions(context),
              ),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có playlist. Hãy import mp3 để tạo.'),
                ),
              for (final p in playlists)
                PlaylistCard(
                  playlist: p,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.playlistDetail,
                    arguments: p,
                  ),
                ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Import mp3 từ Files để tạo playlists theo folder.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
