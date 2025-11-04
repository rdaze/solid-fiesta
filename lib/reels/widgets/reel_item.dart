import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../shared/widgets/blocky_avatar.dart';
import '../models/video_meta.dart';

class ReelItem extends StatefulWidget {
  final String username;
  final bool isLiked;
  final bool isFollowed;
  final List<Comment> comments;
  final String filePath;
  final VideoPlayerController controller;
  final bool isMuted;
  final VoidCallback onToggleMute;

  const ReelItem({
    super.key,
    required this.username,
    required this.isLiked,
    required this.isFollowed,
    required this.comments,
    required this.filePath,
    required this.controller,
    required this.isMuted,
    required this.onToggleMute,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  Uint8List? _thumbnail;

  Future<void> _generateThumbnail() async {
    final thumb = await VideoThumbnail.thumbnailData(
      video: widget.filePath,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
    if (mounted) setState(() => _thumbnail = thumb);
  }

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: _thumbnail != null
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(_thumbnail!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                )
              : Container(color: Colors.black),
        ),
        Center(
          child: GestureDetector(
            onTap: widget.onToggleMute,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: VideoPlayer(widget.controller),
            ),
          ),
        ),
        _buildOverlay(context),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final videoWidth = screenHeight * (9 / 16);
        final horizontalPadding = ((screenWidth - videoWidth) / 2).clamp(
          0,
          screenWidth,
        );
        final theme = Theme.of(context);
        final bool isDark = theme.brightness == Brightness.dark;
        final iconColor = isDark
            ? Colors.white
            : Colors.white.withOpacity(0.90);

        final likedColor = Colors.redAccent;

        return Stack(
          children: [
            Positioned(
              right: horizontalPadding + 16,
              bottom: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      widget.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: widget.isLiked ? likedColor : iconColor,
                      size: 42,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: Icon(Icons.comment, size: 42, color: iconColor),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => SizedBox(
                          height: 600,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'Comments',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(thickness: 1),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: widget.comments.length,
                                  itemBuilder: (_, i) {
                                    final c = widget.comments[i];
                                    return ListTile(
                                      leading: BlockyAvatar(
                                        seed: c.user,
                                        size: 40,
                                      ),
                                      title: Text(c.user),
                                      subtitle: Text(c.comment),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: Icon(Icons.share, size: 42, color: iconColor),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: Icon(Icons.more_horiz, size: 42, color: iconColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Positioned(
              left: horizontalPadding + 16,
              bottom: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      BlockyAvatar(seed: widget.username),
                      const SizedBox(width: 12),
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 12),
                      widget.isFollowed
                          ? ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Followed',
                                style: TextStyle(color: Colors.black),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Follow'),
                            ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: horizontalPadding + 16,
              top: 50,
              child: IconButton(
                icon: Icon(
                  widget.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: iconColor,
                ),
                iconSize: 42,
                onPressed: () {},
              ),
            ),
          ],
        );
      },
    );
  }
}
