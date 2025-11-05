import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/widgets/bottom_bar.dart';
import '../reels/pages/reels_page.dart';
import '../dms/pages/dm_list_page.dart';
import 'settings_page.dart';

class AppShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const AppShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  final GlobalKey<ReelsPageState> _reelsKey = GlobalKey<ReelsPageState>();
  final PageController _tabsController = PageController();

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
  void dispose() {
    _tabsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _tabsController,
        physics:
            const NeverScrollableScrollPhysics(), // lock to bottom bar taps
        onPageChanged: (index) {
          setState(() => _tab = index);
          if (index == 0) {
            _reelsKey.currentState?.setMuted(false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _reelsKey.currentState?.playCurrent();
            }); // auto-unmute on Home
          } else {
            _reelsKey.currentState
              ?..pauseAll()
              ..setMuted(true); // auto-mute on Direct
          }
        },
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
        onTap: (i) async {
          HapticFeedback.selectionClick();
          await _tabsController.animateToPage(
            i,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
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
