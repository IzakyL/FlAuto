import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/notifiers.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode _currentThemeMode = ThemeMode.system;
  static const String _themeModeKey = 'theme_mode';

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey) ?? 2; // 默认为系统模式
    setState(() {
      _currentThemeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    setState(() {
      _currentThemeMode = mode;
    });

    // 通知应用更新主题
    if (mounted) {
      themeNotifier.updateThemeMode(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('主题模式'),
            subtitle: Text(_getThemeModeText()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('亮色'),
                const Text('跟随系统'),
                const Text('暗色'),
              ],
            ),
          ),
          Slider(
            value: _currentThemeMode.index.toDouble(),
            min: 0,
            max: 2,
            divisions: 2,
            onChanged: (value) {
              _saveThemeMode(ThemeMode.values[value.toInt()]);
            },
          ),
        ],
      ),
    );
  }

  String _getThemeModeText() {
    switch (_currentThemeMode) {
      case ThemeMode.light:
        return '亮色模式';
      case ThemeMode.dark:
        return '暗色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }
}