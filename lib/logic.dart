// logic.dart
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

// Models
class MusicFile {
  final String id;
  final String title;
  final String? artist;
  final String filePath;
  final String? imagePath;
  final bool isFavorite;

  MusicFile({
    required this.id,
    required this.title,
    this.artist,
    required this.filePath,
    this.imagePath,
    this.isFavorite = false,
  });

  MusicFile copyWith({
    String? title,
    String? artist,
    String? imagePath,
    bool? isFavorite,
  }) {
    return MusicFile(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      filePath: filePath,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'filePath': filePath,
      'imagePath': imagePath,
      'isFavorite': isFavorite,
    };
  }

  factory MusicFile.fromJson(Map<String, dynamic> json) {
    return MusicFile(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      filePath: json['filePath'],
      imagePath: json['imagePath'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final List<String> musicFileIds;

  Playlist({
    required this.id,
    required this.name,
    required this.musicFileIds,
  });

  Playlist copyWith({
    String? name,
    List<String>? musicFileIds,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      musicFileIds: musicFileIds ?? this.musicFileIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'musicFileIds': musicFileIds,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      musicFileIds: List<String>.from(json['musicFileIds']),
    );
  }
}

// Main Logic Class
class MusicPlayerLogic {
  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Settings
  final ValueNotifier<bool> isDarkMode = ValueNotifier(false);
  final ValueNotifier<String> appTitle = ValueNotifier('Music Player');

  // Music Files
  final ValueNotifier<List<MusicFile>> allMusicFiles = ValueNotifier([]);
  final ValueNotifier<List<MusicFile>> favoriteMusicFiles = ValueNotifier([]);

  // Playlists
  final ValueNotifier<List<Playlist>> playlists = ValueNotifier([]);

  // Player State
  final ValueNotifier<MusicFile?> currentMusicFile = ValueNotifier(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> isLooping = ValueNotifier(false);
  final ValueNotifier<bool> isShuffle = ValueNotifier(false);
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);

  // Play queue
  List<MusicFile> _playQueue = [];
  int _currentQueueIndex = 0;

  // Directories
  Directory? _appDir;
  Directory? _imagesDir;
  Directory? _playlistsDir;

  Future<void> initialize() async {
    try {
      // Setup directories
      await _setupDirectories();

      // Setup audio session for background playback
      await _setupAudioSession();

      // Load saved data
      await _loadSettings();
      await _loadMusicFiles();
      await _loadPlaylists();

      // Setup audio player listeners
      _setupAudioPlayerListeners();

      print('✅ MusicPlayerLogic initialized successfully');
    } catch (e) {
      print('❌ Error initializing MusicPlayerLogic: $e');
    }
  }

  Future<void> _setupDirectories() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _appDir = appDocDir;

      // Create subdirectories
      _imagesDir = Directory('${appDocDir.path}/images');
      _playlistsDir = Directory('${appDocDir.path}/playlists');

      if (!await _imagesDir!.exists()) {
        await _imagesDir!.create(recursive: true);
      }

      if (!await _playlistsDir!.exists()) {
        await _playlistsDir!.create(recursive: true);
      }

      print('✅ Directories created: ${appDocDir.path}');
    } catch (e) {
      print('❌ Error setting up directories: $e');
    }
  }

  Future<void> _setupAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Handle interruptions (calls, etc.)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          _audioPlayer.pause();
        }
      });

      // Handle becoming noisy (headphones unplugged)
      session.becomingNoisyEventStream.listen((_) {
        _audioPlayer.pause();
      });

      print('✅ Audio session configured');
    } catch (e) {
      print('❌ Error setting up audio session: $e');
    }
  }

  void _setupAudioPlayerListeners() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;

      // Auto play next when song completes
      if (state.processingState == ProcessingState.completed) {
        if (isLooping.value) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else {
          playNext();
        }
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      currentPosition.value = position;
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        totalDuration.value = duration;
      }
    });
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
      appTitle.value = prefs.getString('appTitle') ?? 'Music Player';
      isLooping.value = prefs.getBool('isLooping') ?? false;
      isShuffle.value = prefs.getBool('isShuffle') ?? false;

      print('✅ Settings loaded');
    } catch (e) {
      print('❌ Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDarkMode.value);
      await prefs.setString('appTitle', appTitle.value);
      await prefs.setBool('isLooping', isLooping.value);
      await prefs.setBool('isShuffle', isShuffle.value);

      print('✅ Settings saved');
    } catch (e) {
      print('❌ Error saving settings: $e');
    }
  }

  Future<void> _loadMusicFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getString('musicFiles');

      if (filesJson != null) {
        final List<dynamic> decoded = json.decode(filesJson);
        final files = decoded.map((item) => MusicFile.fromJson(item)).toList();

        // Filter out files that don't exist anymore
        final existingFiles = <MusicFile>[];
        for (final file in files) {
          if (await File(file.filePath).exists()) {
            existingFiles.add(file);
          }
        }

        allMusicFiles.value = existingFiles;
        _updateFavorites();

        print('✅ Loaded ${existingFiles.length} music files');
      }
    } catch (e) {
      print('❌ Error loading music files: $e');
    }
  }

  Future<void> _saveMusicFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = json.encode(
        allMusicFiles.value.map((file) => file.toJson()).toList(),
      );
      await prefs.setString('musicFiles', filesJson);

      print('✅ Music files saved');
    } catch (e) {
      print('❌ Error saving music files: $e');
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getString('playlists');

      if (playlistsJson != null) {
        final List<dynamic> decoded = json.decode(playlistsJson);
        playlists.value =
            decoded.map((item) => Playlist.fromJson(item)).toList();

        print('✅ Loaded ${playlists.value.length} playlists');
      }
    } catch (e) {
      print('❌ Error loading playlists: $e');
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = json.encode(
        playlists.value.map((playlist) => playlist.toJson()).toList(),
      );
      await prefs.setString('playlists', playlistsJson);

      print('✅ Playlists saved');
    } catch (e) {
      print('❌ Error saving playlists: $e');
    }
  }

  void _updateFavorites() {
    favoriteMusicFiles.value =
        allMusicFiles.value.where((file) => file.isFavorite).toList();
  }

  void dispose() {
    _audioPlayer.dispose();
    isDarkMode.dispose();
    appTitle.dispose();
    allMusicFiles.dispose();
    favoriteMusicFiles.dispose();
    playlists.dispose();
    currentMusicFile.dispose();
    isPlaying.dispose();
    isLooping.dispose();
    isShuffle.dispose();
    currentPosition.dispose();
    totalDuration.dispose();
  }

  // Settings Methods
  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    _saveSettings();
  }

  void setAppTitle(String title) {
    appTitle.value = title;
    _saveSettings();
  }

  // Music File Methods
  Future<void> addMusicFiles(List<String> extensions) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newFiles = <MusicFile>[];

        for (final file in result.files) {
          if (file.path != null) {
            // Generate unique ID
            final id = DateTime.now().millisecondsSinceEpoch.toString() +
                Random().nextInt(1000).toString();

            // Copy file to app directory
            final originalFile = File(file.path!);
            final fileName = file.name;
            final newPath = '${_appDir!.path}/$fileName';
            final newFile = await originalFile.copy(newPath);

            // Extract title from filename (remove extension)
            final title = fileName.replaceAll(
                RegExp(r'\.(mp3|m4a)$', caseSensitive: false), '');

            // Create MusicFile object
            final musicFile = MusicFile(
              id: id,
              title: title,
              filePath: newFile.path,
            );

            newFiles.add(musicFile);
            print('✅ Added file: $title');
          }
        }

        if (newFiles.isNotEmpty) {
          allMusicFiles.value = [...allMusicFiles.value, ...newFiles];
          await _saveMusicFiles();
          print('✅ Successfully added ${newFiles.length} files');
        }
      }
    } catch (e) {
      print('❌ Error adding music files: $e');
    }
  }

  Future<void> deleteMusicFile(String id) async {
    try {
      final file = allMusicFiles.value.firstWhere((f) => f.id == id);

      // Delete file from filesystem
      final audioFile = File(file.filePath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      // Delete associated image if exists
      if (file.imagePath != null) {
        final imageFile = File(file.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Remove from all playlists
      for (final playlist in playlists.value) {
        if (playlist.musicFileIds.contains(id)) {
          final updatedIds =
              playlist.musicFileIds.where((fid) => fid != id).toList();
          final index = playlists.value.indexOf(playlist);
          final updatedPlaylist = playlist.copyWith(musicFileIds: updatedIds);
          final updatedPlaylists = [...playlists.value];
          updatedPlaylists[index] = updatedPlaylist;
          playlists.value = updatedPlaylists;
        }
      }
      await _savePlaylists();

      // Remove from music files list
      allMusicFiles.value =
          allMusicFiles.value.where((f) => f.id != id).toList();
      _updateFavorites();
      await _saveMusicFiles();

      // Stop playing if this was the current file
      if (currentMusicFile.value?.id == id) {
        await _audioPlayer.stop();
        currentMusicFile.value = null;
      }

      print('✅ Deleted file: ${file.title}');
    } catch (e) {
      print('❌ Error deleting music file: $e');
    }
  }

  Future<void> renameMusicFile(String id, String newTitle) async {
    try {
      final index = allMusicFiles.value.indexWhere((f) => f.id == id);
      if (index != -1) {
        final file = allMusicFiles.value[index];
        final updatedFile = file.copyWith(title: newTitle);
        final updatedList = [...allMusicFiles.value];
        updatedList[index] = updatedFile;
        allMusicFiles.value = updatedList;
        _updateFavorites();
        await _saveMusicFiles();

        print('✅ Renamed to: $newTitle');
      }
    } catch (e) {
      print('❌ Error renaming music file: $e');
    }
  }

  Future<void> addImageToMusicFile(String id) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = image.path.split('.').last;
        final newFileName = '${id}_$timestamp.$extension';
        final newPath = '${_imagesDir!.path}/$newFileName';

        // Copy image to app's images directory
        final imageFile = File(image.path);
        await imageFile.copy(newPath);

        // Update music file with image path
        final index = allMusicFiles.value.indexWhere((f) => f.id == id);
        if (index != -1) {
          final file = allMusicFiles.value[index];

          // Delete old image if exists
          if (file.imagePath != null) {
            final oldImage = File(file.imagePath!);
            if (await oldImage.exists()) {
              await oldImage.delete();
            }
          }

          final updatedFile = file.copyWith(imagePath: newPath);
          final updatedList = [...allMusicFiles.value];
          updatedList[index] = updatedFile;
          allMusicFiles.value = updatedList;
          _updateFavorites();
          await _saveMusicFiles();

          print('✅ Image added to: ${file.title}');
        }
      }
    } catch (e) {
      print('❌ Error adding image: $e');
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final index = allMusicFiles.value.indexWhere((f) => f.id == id);
      if (index != -1) {
        final file = allMusicFiles.value[index];
        final updatedFile = file.copyWith(isFavorite: !file.isFavorite);
        final updatedList = [...allMusicFiles.value];
        updatedList[index] = updatedFile;
        allMusicFiles.value = updatedList;
        _updateFavorites();
        await _saveMusicFiles();

        print('✅ Favorite toggled for: ${file.title}');
      }
    } catch (e) {
      print('❌ Error toggling favorite: $e');
    }
  }

  // Playlist Methods
  Future<void> createPlaylist(String name) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final playlist = Playlist(
        id: id,
        name: name,
        musicFileIds: [],
      );

      playlists.value = [...playlists.value, playlist];
      await _savePlaylists();

      print('✅ Created playlist: $name');
    } catch (e) {
      print('❌ Error creating playlist: $e');
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      playlists.value = playlists.value.where((p) => p.id != id).toList();
      await _savePlaylists();

      print('✅ Deleted playlist');
    } catch (e) {
      print('❌ Error deleting playlist: $e');
    }
  }

  Future<void> renamePlaylist(String id, String newName) async {
    try {
      final index = playlists.value.indexWhere((p) => p.id == id);
      if (index != -1) {
        final playlist = playlists.value[index];
        final updatedPlaylist = playlist.copyWith(name: newName);
        final updatedList = [...playlists.value];
        updatedList[index] = updatedPlaylist;
        playlists.value = updatedList;
        await _savePlaylists();

        print('✅ Renamed playlist to: $newName');
      }
    } catch (e) {
      print('❌ Error renaming playlist: $e');
    }
  }

  Future<void> addToPlaylist(String playlistId, String musicFileId) async {
    try {
      final index = playlists.value.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final playlist = playlists.value[index];
        if (!playlist.musicFileIds.contains(musicFileId)) {
          final updatedIds = [...playlist.musicFileIds, musicFileId];
          final updatedPlaylist = playlist.copyWith(musicFileIds: updatedIds);
          final updatedList = [...playlists.value];
          updatedList[index] = updatedPlaylist;
          playlists.value = updatedList;
          await _savePlaylists();

          print('✅ Added to playlist');
        }
      }
    } catch (e) {
      print('❌ Error adding to playlist: $e');
    }
  }

  Future<void> removeFromPlaylist(String playlistId, String musicFileId) async {
    try {
      final index = playlists.value.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final playlist = playlists.value[index];
        final updatedIds =
            playlist.musicFileIds.where((id) => id != musicFileId).toList();
        final updatedPlaylist = playlist.copyWith(musicFileIds: updatedIds);
        final updatedList = [...playlists.value];
        updatedList[index] = updatedPlaylist;
        playlists.value = updatedList;
        await _savePlaylists();

        print('✅ Removed from playlist');
      }
    } catch (e) {
      print('❌ Error removing from playlist: $e');
    }
  }

  // Player Methods
  Future<void> playMusic(MusicFile file) async {
    try {
      currentMusicFile.value = file;

      // Setup play queue
      _playQueue = [...allMusicFiles.value];
      _currentQueueIndex = _playQueue.indexWhere((f) => f.id == file.id);

      if (isShuffle.value) {
        _shuffleQueue();
      }

      // Play the file
      await _audioPlayer.setFilePath(file.filePath);
      await _audioPlayer.play();

      print('✅ Playing: ${file.title}');
    } catch (e) {
      print('❌ Error playing music: $e');
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (isPlaying.value) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      print('❌ Error toggling play/pause: $e');
    }
  }

  Future<void> playNext() async {
    try {
      if (_playQueue.isEmpty) return;

      _currentQueueIndex = (_currentQueueIndex + 1) % _playQueue.length;
      final nextFile = _playQueue[_currentQueueIndex];
      currentMusicFile.value = nextFile;

      await _audioPlayer.setFilePath(nextFile.filePath);
      await _audioPlayer.play();

      print('✅ Playing next: ${nextFile.title}');
    } catch (e) {
      print('❌ Error playing next: $e');
    }
  }

  Future<void> playPrevious() async {
    try {
      if (_playQueue.isEmpty) return;

      // If more than 3 seconds into song, restart current song
      if (currentPosition.value.inSeconds > 3) {
        await _audioPlayer.seek(Duration.zero);
        return;
      }

      _currentQueueIndex =
          (_currentQueueIndex - 1 + _playQueue.length) % _playQueue.length;
      final prevFile = _playQueue[_currentQueueIndex];
      currentMusicFile.value = prevFile;

      await _audioPlayer.setFilePath(prevFile.filePath);
      await _audioPlayer.play();

      print('✅ Playing previous: ${prevFile.title}');
    } catch (e) {
      print('❌ Error playing previous: $e');
    }
  }

  Future<void> toggleLoop() async {
    try {
      isLooping.value = !isLooping.value;
      await _audioPlayer.setLoopMode(
        isLooping.value ? LoopMode.one : LoopMode.off,
      );
      await _saveSettings();

      print('✅ Loop mode: ${isLooping.value}');
    } catch (e) {
      print('❌ Error toggling loop: $e');
    }
  }

  void toggleShuffle() {
    isShuffle.value = !isShuffle.value;

    if (isShuffle.value) {
      _shuffleQueue();
    } else {
      _playQueue = [...allMusicFiles.value];
      if (currentMusicFile.value != null) {
        _currentQueueIndex = _playQueue.indexWhere(
          (f) => f.id == currentMusicFile.value!.id,
        );
      }
    }

    _saveSettings();
    print('✅ Shuffle mode: ${isShuffle.value}');
  }

  void _shuffleQueue() {
    final currentFile = currentMusicFile.value;
    _playQueue.shuffle();

    // Make sure current song is first in shuffled queue
    if (currentFile != null) {
      _playQueue.removeWhere((f) => f.id == currentFile.id);
      _playQueue.insert(0, currentFile);
      _currentQueueIndex = 0;
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('❌ Error seeking: $e');
    }
  }
}
