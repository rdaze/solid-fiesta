import 'package:flutter/material.dart';
import '../models/chat_thread.dart';
import '../../shared/widgets/blocky_avatar.dart';

class DmThreadPage extends StatelessWidget {
  final ChatThread thread;
  const DmThreadPage({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            BlockyAvatar(seed: thread.user, size: 32),
            const SizedBox(width: 12),
            Text(thread.user),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: thread.messages.length,
        itemBuilder: (context, i) {
          final m = thread.messages[i];
          final isMe = m.fromMe;
          final displayName = isMe ? 'Du' : (m.sender ?? thread.user);
          final isGroup = thread.messages.any(
            (msg) => !msg.fromMe && msg.sender != null && msg.sender!.isNotEmpty,
          );

          final prev = i > 0 ? thread.messages[i - 1] : null;
          final sameSenderAsPrev =
              prev != null &&
              prev.fromMe == m.fromMe &&
              (prev.sender ?? '') == (m.sender ?? '');

          // --- Day separator logic ---
          bool showDayHeader = false;
          if (m.timestamp != null) {
            final prevTs = prev?.timestamp;
            final cur = m.timestamp!.toLocal();
            final prevLocal = prevTs?.toLocal();
            showDayHeader = prevLocal == null ||
                cur.day != prevLocal.day ||
                cur.month != prevLocal.month ||
                cur.year != prevLocal.year;
          }

          if (showDayHeader) {
            final formatted = MaterialLocalizations.of(context)
                .formatFullDate(m.timestamp!.toLocal());
            return Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      formatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                _buildMessageBubble(
                  context: context,
                  m: m,
                  isMe: isMe,
                  sameSenderAsPrev: sameSenderAsPrev,
                  displayName: displayName,
                  isGroup: isGroup,
                ),
              ],
            );
          }

          // Default: just the message bubble
          return _buildMessageBubble(
            context: context,
            m: m,
            isMe: isMe,
            sameSenderAsPrev: sameSenderAsPrev,
            displayName: displayName,
            isGroup: isGroup,
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble({
    required BuildContext context,
    required ChatMessage m,
    required bool isMe,
    required bool sameSenderAsPrev,
    required String displayName,
    required bool isGroup,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor = isMe
        ? Colors.blueAccent
        : (isDark ? Colors.white10 : Colors.grey.shade300);

    final textColor = isMe
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);

    final nameColor = theme.colorScheme.onSurface.withOpacity(0.6);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Name shown only for others and only when the speaker changes
            if (isGroup && !isMe && !sameSenderAsPrev) ...[
              Text(
                displayName,
                style: TextStyle(fontSize: 12, color: nameColor),
              ),
              const SizedBox(height: 2),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                m.text,
                style: TextStyle(color: textColor, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
