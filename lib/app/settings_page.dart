import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final ThemeMode currentMode;
  const SettingsPage({super.key, required this.currentMode});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.currentMode;
  }

  void _setMode(ThemeMode m) {
    setState(() => _mode = m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const ListTile(title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold))),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: _mode,
            title: const Text('Light'),
            onChanged: (m) => _setMode(m!),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: _mode,
            title: const Text('Dark'),
            onChanged: (m) => _setMode(m!),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: _mode,
            title: const Text('System'),
            onChanged: (m) => _setMode(m!),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_mode),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}