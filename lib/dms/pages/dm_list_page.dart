import 'package:flutter/material.dart';
import '../../app/app_constants.dart';
import '../models/chat_thread.dart';
import '../services/dm_loader.dart';
import 'dm_thread_page.dart';
import '../../shared/widgets/blocky_avatar.dart';

class DmListPage extends StatefulWidget {
  const DmListPage({super.key});

  @override
  State<DmListPage> createState() => _DmListPageState();
}

class _DmListPageState extends State<DmListPage> {
  late Future<List<ChatThread>> _threadsFuture;

  @override
  void initState() {
    super.initState();
    _threadsFuture = DmLoader.loadThreadsForProfile(AppConstants.profileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Direct Messages'), centerTitle: true),
      body: FutureBuilder<List<ChatThread>>(
        future: _threadsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load chats: ${snap.error}'));
          }
          final threads = snap.data ?? [];
          if (threads.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }
          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = threads[i];
              return ListTile(
                leading: BlockyAvatar(seed: t.user, size: 40),
                title: Text(t.user),
                subtitle: Text(
                  t.messages.isNotEmpty ? t.messages.last.text : 'No messages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DmThreadPage(thread: t)),
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
