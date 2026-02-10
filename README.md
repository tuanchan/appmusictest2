# 🎵 Music Player - iOS App

Ứng dụng phát nhạc cho iPhone với giao diện lấy cảm hứng từ SoundCloud, màu cam chủ đạo #FF4A00.

## ✨ Tính năng

### 🎨 Giao diện
- ✅ Màu chủ đạo: Cam #FF4A00 (SoundCloud-inspired)
- ✅ Màu nền tối: #121212
- ✅ Giao diện gọn gàng, dễ sử dụng
- ✅ 4 tab chính: Home, Yêu thích, Danh sách phát, Settings
- ✅ Màn hình phát nhạc đầy đủ với progress bar

### 🎵 Phát nhạc
- Hỗ trợ MP3 và MPEG-4 Apple (M4A)
- Phát nhạc trong nền
- Hiển thị trên lock screen (như YouTube Premium)
- Loop (lặp lại bài hát)
- Shuffle (phát ngẫu nhiên)
- Phát liên tục

### 📁 Quản lý file
- Thêm nhiều file cùng lúc
- App có folder riêng trong "Trên iPhone"
- Sửa tên bài hát
- Thêm/thay đổi ảnh bìa
- Xóa file (swipe to delete)

### ⭐ Yêu thích & Playlist
- Thêm bài hát vào yêu thích
- Tạo danh sách phát
- Quản lý playlist

### ⚙️ Settings
- Chế độ sáng/tối
- Đổi tên app title
- Tất cả settings được lưu lại

## 📱 Cài đặt

### Yêu cầu
- iPhone chạy iOS 12.0 trở lên
- Sideloadly hoặc ESign để cài đặt IPA

### Build từ source

1. **Clone repository**
```bash
git clone https://github.com/yourusername/music_player.git
cd music_player
```

2. **Cài đặt dependencies**
```bash
flutter pub get
```

3. **Build IPA**
```bash
flutter build ios --release --no-codesign
```

4. **Tạo IPA file**
```bash
mkdir Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r MusicPlayer.ipa Payload
```

### Cài đặt qua GitHub Actions

1. Fork repository này
2. Push code lên GitHub
3. GitHub Actions sẽ tự động build IPA
4. Download IPA từ Actions artifacts
5. Cài đặt bằng Sideloadly hoặc ESign

## 🛠️ Cấu trúc dự án

```
music_player/
├── lib/
│   ├── main.dart          # Entry point
│   ├── app.dart           # UI - Toàn bộ giao diện
│   └── logic.dart         # Logic - Xử lý nghiệp vụ
├── ios/
│   └── Runner/
│       └── Info.plist     # iOS configuration
├── .github/
│   └── workflows/
│       └── build-ios.yml  # GitHub Actions workflow
├── pubspec.yaml           # Dependencies
├── CHECKLIST.md           # Implementation checklist
└── README.md
```

## 📋 Checklist Implementation

Xem file [CHECKLIST.md](CHECKLIST.md) để theo dõi tiến độ implement các tính năng.

**Trạng thái hiện tại:**
- ✅ UI: 100% hoàn thành
- ⏳ Logic: Chờ implement

## 🔧 Công nghệ sử dụng

- **Framework**: Flutter
- **Audio Player**: just_audio
- **Background Audio**: audio_session  
- **File Picker**: file_picker, image_picker
- **Metadata**: audiotagger
- **Storage**: shared_preferences, path_provider
- **Permissions**: permission_handler

## 📦 Dependencies

```yaml
dependencies:
  just_audio: ^0.9.36
  audio_session: ^0.1.18
  file_picker: ^6.1.1
  image_picker: ^1.0.7
  path_provider: ^2.1.2
  audiotagger: ^2.2.1
  shared_preferences: ^2.2.2
  permission_handler: ^11.2.0
  uuid: ^4.3.3
```

## 🎯 Roadmap

### Phase 1: UI ✅
- [x] Thiết kế giao diện hoàn chỉnh
- [x] Tất cả các màn hình
- [x] Bottom navigation
- [x] Player screen

### Phase 2: Logic (In Progress)
- [ ] Audio playback implementation
- [ ] File management
- [ ] Metadata extraction
- [ ] Favorites & Playlists
- [ ] Settings persistence

### Phase 3: iOS Features
- [ ] Background audio
- [ ] Lock screen controls
- [ ] Files app integration
- [ ] Notifications

### Phase 4: Polish
- [ ] Error handling
- [ ] Loading states
- [ ] Animations
- [ ] Testing

## 🔐 Build & Deploy

App được build **KHÔNG CẦN** code signing certificate:
- ✅ Free app
- ✅ No provisioning profile
- ✅ Compatible với Sideloadly
- ✅ Compatible với ESign
- ✅ GitHub Actions workflow included

## 📸 Screenshots

*(Screenshots sẽ được thêm sau khi app hoàn thành)*

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is open source and available under the MIT License.

## 👨‍💻 Author

Built with ❤️ for iOS music lovers

## 🙏 Acknowledgments

- Inspired by SoundCloud's design
- Built with Flutter
- Uses amazing open-source packages

---

**Note**: Đây là phiên bản đầu tiên với UI hoàn chỉnh. Logic đang được phát triển.
