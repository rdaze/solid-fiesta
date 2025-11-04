import 'package:flutter/material.dart';
import '../shared/widgets/bottom_bar.dart';
import '../reels/pages/reels_page.dart';
import '../dms/pages/dm_list_page.dart';
import 'settings_page.dart';

class AppShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const AppShell({super.key, required this.themeMode, required this.onThemeModeChanged});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  final GlobalKey<ReelsPageState> _reelsKey = GlobalKey<ReelsPageState>();

  void _openSettings() async {
    final newMode = await Navigator.of(context).push<ThemeMode>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(currentMode: widget.themeMode),
      ),
    );
    if (newMode != null) {
      widget.onThemeModeChanged(newMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          ReelsPage(key: _reelsKey),
          const DmListPage(),
        ],
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _tab,
        items: const [
          BottomBarItem(icon: Icons.home_filled, label: 'Home'),
          BottomBarItem(icon: Icons.mail_outline, label: 'Direct'),
        ],
        onTap: (i) {
          setState(() => _tab = i);
          if (i == 0) {
            _reelsKey.currentState?.setMuted(false); // auto-unmute on Home
          } else if (i == 1) {
            _reelsKey.currentState?.setMuted(true); // auto-mute on Direct
          }
        },
        rightAction: IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: _openSettings,
        ),
      ),
    );
  }
}