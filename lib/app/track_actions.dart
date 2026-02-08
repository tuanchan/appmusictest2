// app/track_actions.dart
import 'package:flutter/material.dart';
import '../models/track.dart';
import 'library_scope.dart';

Future<void> showTrackOptions(BuildContext context, Track track) async {
  final library = LibraryScope.of(context);

  await showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Thêm vào playlist'),
              onTap: () async {
                Navigator.of(context).pop();
                await library.addTrackToPlaylist(context, track: track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text('Chọn ảnh'),
              onTap: () async {
                Navigator.of(context).pop();
                await library.setArtwork(context, track);
              },
            ),
            if (track.artworkPath != null && track.artworkPath!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Xóa ảnh'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await library.clearArtwork(track);
                },
              ),
          ],
        ),
      );
    },
  );
}
