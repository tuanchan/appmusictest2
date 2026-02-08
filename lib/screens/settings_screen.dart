// screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../widgets/blur_app_bar.dart';
import '../app/settings_scope.dart';
import '../app/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController? _titleCtrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = SettingsScope.of(context);

    // init 1 lần, tránh tạo lại khi rebuild
    _titleCtrl ??= TextEditingController(text: settings.appTitle);
  }

  @override
  void dispose() {
    _titleCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);

    // source-of-truth từ controller
    final isDark = settings.themeMode == ThemeMode.dark;

    final orange = AppTheme.soundCloudOrange;

    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final pageBg = isDark ? const Color(0xFF0B0F14) : const Color(0xFFF6F6F7);
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: const BlurAppBar(title: 'Cài đặt'),
      body: Container(
        color: pageBg,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            // Card 1: Theme
            Card(
              color: cardBg,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giao diện',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Chế độ tối',
                          style: TextStyle(color: textColor)),
                      value: isDark,
                      onChanged: (v) async {
                        await settings.setThemeMode(
                          v ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Card 2: App title
            Card(
              color: cardBg,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên hiển thị góc trái',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 10),

                    // ✅ TextField đặt tên (bị mất của anh nằm ở đây)
                    TextField(
                      controller: _titleCtrl,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Nhập tên app...',
                        hintStyle: TextStyle(color: hintColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: orange.withOpacity(0.95),
                            width: 1.4,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF0B0F14) : Colors.white,
                      ),
                      onSubmitted: (v) async {
                        await settings.setAppTitle(v);
                        if (!mounted) return;
                        FocusScope.of(context).unfocus();
                      },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          await settings.setAppTitle(_titleCtrl?.text ?? '');
                          if (!mounted) return;
                          FocusScope.of(context).unfocus();
                        },
                        child: const Text('Lưu tên'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
