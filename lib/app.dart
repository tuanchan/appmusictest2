import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'logic.dart';

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFFFF4A00),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFFF4A00),
          secondary: const Color(0xFFFF4A00),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFF4A00),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF4A00),
          secondary: const Color(0xFFFF4A00),
          surface: const Color(0xFF1E1E1E),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final MusicPlayerLogic _logic = MusicPlayerLogic();

  @override
  void initState() {
    super.initState();
    _logic.initialize();
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(logic: _logic),
          FavoritesScreen(logic: _logic),
          PlaylistsScreen(logic: _logic),
          SettingsScreen(logic: _logic),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.favorite_rounded,
                  label: 'Yêu thích',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.library_music_rounded,
                  label: 'Danh sách',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFFFF4A00)
        : Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[600];

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF4A00).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// HOME SCREEN
class HomeScreen extends StatefulWidget {
  final MusicPlayerLogic logic;

  const HomeScreen({super.key, required this.logic});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white,
        elevation: 0,
        title: ValueListenableBuilder<String>(
          valueListenable: widget.logic.appTitle,
          builder: (context, title, child) {
            return Text(
              title,
              style: TextStyle(
                color: const Color(0xFFFF4A00),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFFF4A00)),
            onPressed: () => _showAddFilesDialog(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<MusicFile>>(
        valueListenable: widget.logic.allMusicFiles,
        builder: (context, files, child) {
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có nhạc nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn + để thêm nhạc',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return _buildMusicFileItem(context, files[index], index);
            },
          );
        },
      ),
    );
  }

  Widget _buildMusicFileItem(BuildContext context, MusicFile file, int index) {
    return Dismissible(
      key: Key(file.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa bài hát'),
            content: Text('Bạn có chắc muốn xóa "${file.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        widget.logic.deleteMusicFile(file.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa "${file.title}"')),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: file.imagePath != null
                ? DecorationImage(
                    image: AssetImage(file.imagePath!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: const Color(0xFFFF4A00).withOpacity(0.1),
          ),
          child: file.imagePath == null
              ? const Icon(Icons.music_note_rounded, color: Color(0xFFFF4A00))
              : null,
        ),
        title: Text(
          file.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          file.artist ?? 'Unknown Artist',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showMusicFileOptions(context, file),
        ),
        onTap: () {
          widget.logic.playMusic(file);
          _showPlayerScreen(context);
        },
      ),
    );
  }

  void _showAddFilesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.audio_file_rounded, color: Color(0xFFFF4A00)),
                title: const Text('Thêm file MP3'),
                onTap: () {
                  Navigator.pop(context);
                  widget.logic.addMusicFiles(['mp3']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.audio_file_rounded, color: Color(0xFFFF4A00)),
                title: const Text('Thêm file MPEG-4 Apple'),
                onTap: () {
                  Navigator.pop(context);
                  widget.logic.addMusicFiles(['m4a']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_add_rounded, color: Color(0xFFFF4A00)),
                title: const Text('Thêm nhiều file'),
                onTap: () {
                  Navigator.pop(context);
                  widget.logic.addMusicFiles(['mp3', 'm4a']);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMusicFileOptions(BuildContext context, MusicFile file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_rounded, color: Color(0xFFFF4A00)),
                title: const Text('Thêm ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  widget.logic.addImageToMusicFile(file.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Color(0xFFFF4A00)),
                title: const Text('Sửa tên'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditNameDialog(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_rounded, color: Color(0xFFFF4A00)),
                title: Text(file.isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích'),
                onTap: () {
                  Navigator.pop(context);
                  widget.logic.toggleFavorite(file.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('Xóa file', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  widget.logic.deleteMusicFile(file.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, MusicFile file) {
    final controller = TextEditingController(text: file.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa tên bài hát'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              widget.logic.renameMusicFile(file.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showPlayerScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(logic: widget.logic),
      ),
    );
  }
}

// FAVORITES SCREEN
class FavoritesScreen extends StatelessWidget {
  final MusicPlayerLogic logic;

  const FavoritesScreen({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white,
        elevation: 0,
        title: const Text(
          'Yêu thích',
          style: TextStyle(
            color: Color(0xFFFF4A00),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<MusicFile>>(
        valueListenable: logic.favoriteMusicFiles,
        builder: (context, favorites, child) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài hát yêu thích',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final file = favorites[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: file.imagePath != null
                        ? DecorationImage(
                            image: AssetImage(file.imagePath!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: const Color(0xFFFF4A00).withOpacity(0.1),
                  ),
                  child: file.imagePath == null
                      ? const Icon(Icons.music_note_rounded, color: Color(0xFFFF4A00))
                      : null,
                ),
                title: Text(
                  file.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  file.artist ?? 'Unknown Artist',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Color(0xFFFF4A00)),
                  onPressed: () => logic.toggleFavorite(file.id),
                ),
                onTap: () {
                  logic.playMusic(file);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(logic: logic),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// PLAYLISTS SCREEN
class PlaylistsScreen extends StatelessWidget {
  final MusicPlayerLogic logic;

  const PlaylistsScreen({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white,
        elevation: 0,
        title: const Text(
          'Danh sách phát',
          style: TextStyle(
            color: Color(0xFFFF4A00),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFFF4A00)),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Playlist>>(
        valueListenable: logic.playlists,
        builder: (context, playlists, child) {
          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_music_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có danh sách phát',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn + để tạo mới',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFFF4A00).withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.queue_music_rounded,
                      color: Color(0xFFFF4A00),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    playlist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${playlist.musicFileIds.length} bài hát',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _showPlaylistOptions(context, playlist),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(
                          logic: logic,
                          playlist: playlist,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo danh sách phát mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tên danh sách',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                logic.createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Color(0xFFFF4A00)),
                title: const Text('Đổi tên'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenamePlaylistDialog(context, playlist);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  logic.deletePlaylist(playlist.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenamePlaylistDialog(BuildContext context, Playlist playlist) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên danh sách phát'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tên mới',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                logic.renamePlaylist(playlist.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

// PLAYLIST DETAIL SCREEN
class PlaylistDetailScreen extends StatelessWidget {
  final MusicPlayerLogic logic;
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.logic,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFF4A00)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          playlist.name,
          style: const TextStyle(
            color: Color(0xFFFF4A00),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFFF4A00)),
            onPressed: () => _showAddToPlaylistDialog(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<MusicFile>>(
        valueListenable: logic.allMusicFiles,
        builder: (context, allFiles, child) {
          final playlistFiles = allFiles
              .where((file) => playlist.musicFileIds.contains(file.id))
              .toList();

          if (playlistFiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_music_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Danh sách trống',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn + để thêm bài hát',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: playlistFiles.length,
            itemBuilder: (context, index) {
              final file = playlistFiles[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: file.imagePath != null
                        ? DecorationImage(
                            image: AssetImage(file.imagePath!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: const Color(0xFFFF4A00).withOpacity(0.1),
                  ),
                  child: file.imagePath == null
                      ? const Icon(Icons.music_note_rounded, color: Color(0xFFFF4A00))
                      : null,
                ),
                title: Text(
                  file.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  file.artist ?? 'Unknown Artist',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red),
                  onPressed: () {
                    logic.removeFromPlaylist(playlist.id, file.id);
                  },
                ),
                onTap: () {
                  logic.playMusic(file);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(logic: logic),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ValueListenableBuilder<List<MusicFile>>(
          valueListenable: logic.allMusicFiles,
          builder: (context, allFiles, child) {
            final availableFiles = allFiles
                .where((file) => !playlist.musicFileIds.contains(file.id))
                .toList();

            if (availableFiles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Không có bài hát nào để thêm',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              itemCount: availableFiles.length,
              itemBuilder: (context, index) {
                final file = availableFiles[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFFFF4A00).withOpacity(0.1),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Color(0xFFFF4A00), size: 20),
                  ),
                  title: Text(file.title),
                  onTap: () {
                    logic.addToPlaylist(playlist.id, file.id);
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// SETTINGS SCREEN
class SettingsScreen extends StatelessWidget {
  final MusicPlayerLogic logic;

  const SettingsScreen({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFFFF4A00),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giao diện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: logic.isDarkMode,
                    builder: (context, isDark, child) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Chế độ tối'),
                        subtitle: const Text('Bật/tắt giao diện tối'),
                        value: isDark,
                        activeColor: const Color(0xFFFF4A00),
                        onChanged: (value) {
                          logic.toggleDarkMode();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tên ứng dụng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<String>(
                    valueListenable: logic.appTitle,
                    builder: (context, title, child) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text('Nhấn để thay đổi'),
                        trailing: const Icon(Icons.edit_rounded, color: Color(0xFFFF4A00)),
                        onTap: () => _showEditTitleDialog(context),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Phiên bản'),
                    subtitle: const Text('1.0.0'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Định dạng hỗ trợ'),
                    subtitle: const Text('MP3, MPEG-4 Apple (M4A)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTitleDialog(BuildContext context) {
    final controller = TextEditingController(text: logic.appTitle.value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên ứng dụng'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                logic.setAppTitle(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

// PLAYER SCREEN
class PlayerScreen extends StatelessWidget {
  final MusicPlayerLogic logic;

  const PlayerScreen({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF4A00).withOpacity(0.3),
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF121212)
                  : Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Now Playing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Album art
              ValueListenableBuilder<MusicFile?>(
                valueListenable: logic.currentMusicFile,
                builder: (context, file, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4A00).withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: file?.imagePath != null
                          ? DecorationImage(
                              image: AssetImage(file!.imagePath!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: const Color(0xFFFF4A00).withOpacity(0.2),
                    ),
                    child: file?.imagePath == null
                        ? const Icon(
                            Icons.music_note_rounded,
                            size: 100,
                            color: Color(0xFFFF4A00),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(height: 40),
              // Song info
              ValueListenableBuilder<MusicFile?>(
                valueListenable: logic.currentMusicFile,
                builder: (context, file, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          file?.title ?? 'No song playing',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          file?.artist ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    ValueListenableBuilder<Duration>(
                      valueListenable: logic.currentPosition,
                      builder: (context, position, child) {
                        return ValueListenableBuilder<Duration>(
                          valueListenable: logic.totalDuration,
                          builder: (context, duration, child) {
                            final progress = duration.inMilliseconds > 0
                                ? position.inMilliseconds / duration.inMilliseconds
                                : 0.0;
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16,
                                    ),
                                  ),
                                  child: Slider(
                                    value: progress.clamp(0.0, 1.0),
                                    activeColor: const Color(0xFFFF4A00),
                                    inactiveColor: Colors.grey[300],
                                    onChanged: (value) {
                                      logic.seekTo(
                                        Duration(
                                          milliseconds: (value * duration.inMilliseconds).round(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: logic.isLooping,
                      builder: (context, isLooping, child) {
                        return IconButton(
                          icon: Icon(
                            isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                            color: isLooping ? const Color(0xFFFF4A00) : Colors.grey,
                          ),
                          iconSize: 28,
                          onPressed: () => logic.toggleLoop(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 40,
                      onPressed: () => logic.playPrevious(),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: logic.isPlaying,
                      builder: (context, isPlaying, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF4A00),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4A00).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            iconSize: 48,
                            onPressed: () => logic.togglePlayPause(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 40,
                      onPressed: () => logic.playNext(),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: logic.isShuffle,
                      builder: (context, isShuffle, child) {
                        return IconButton(
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: isShuffle ? const Color(0xFFFF4A00) : Colors.grey,
                          ),
                          iconSize: 28,
                          onPressed: () => logic.toggleShuffle(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
