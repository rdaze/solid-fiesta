import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:blockies/blockies.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'dart:io';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import 'comment.dart';

Future<Map<String, VideoMeta>> loadVideoMetadata() async {
  final jsonStr = await rootBundle.loadString('assets/video_metadata.json');
  final jsonData = json.decode(jsonStr);

  final List videos = jsonData['videos'];
  final metadata = {
    for (var v in videos) v['filename'] as String: VideoMeta.fromJson(v),
  };

  return metadata;
}

Future<List<String>> loadVideoFilenamesFromMetadata() async {
  final jsonStr = await rootBundle.loadString('assets/video_metadata.json');
  final jsonData = json.decode(jsonStr);
  final List videos = jsonData['videos'];

  return videos.map((v) => v['filename'] as String).toList();
}

Future<List<File>> copyAssetVideosToLocal() async {
  final filenames = await loadVideoFilenamesFromMetadata();

  final appDir = await getApplicationDocumentsDirectory();
  final videoDir = Directory('${appDir.path}/videos');
  if (!videoDir.existsSync()) {
    videoDir.createSync(recursive: true);
  }

  List<File> copiedFiles = [];

  for (final name in filenames) {
    final assetPath = 'assets/videos/$name';
    final localPath = '${videoDir.path}/$name';

    final byteData = await rootBundle.load(assetPath);
    final file = File(localPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    copiedFiles.add(file);
  }

  return copiedFiles;
}

Future<List<File>> loadVideoFiles() async {
  final status = await Permission.storage.request();
  if (!status.isGranted) return [];

  final Directory? dir = await getExternalStorageDirectory();
  if (dir == null) return [];

  final videoDir = Directory('${dir.path}/videos');

  if (!videoDir.existsSync()) {
    videoDir.createSync(recursive: true);
    return [];
  }

  final files = videoDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.mp4'))
      .toList();

  return files;
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reels Clone',
      theme: ThemeData.dark(),
      home: ReelsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  List<File> videoFiles = [];
  late Map<String, VideoMeta> videoMetadata;
  bool loading = true;
  Map<int, VideoPlayerController> _controllerCache = {};
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    Future.wait([copyAssetVideosToLocal(), loadVideoMetadata()]).then((
      results,
    ) {
      final List<File> files = results[0] as List<File>;
      final Map<String, VideoMeta> metadata =
          results[1] as Map<String, VideoMeta>;

      final filteredFiles = files.where((file) {
        final name = file.path.split('/').last;
        return metadata.containsKey(name);
      }).toList();

      setState(() {
        videoFiles = filteredFiles;
        videoMetadata = metadata;
        loading = false;
      });

      _preloadControllers(0); // preload first + next
    });
  }

  @override
  void dispose() {
    for (final controller in _controllerCache.values) {
      controller.dispose();
    }
    _controllerCache.clear();
    super.dispose();
  }

  void _preloadControllers(int pageIndex) async {
    List<int> toKeep = [pageIndex - 1, pageIndex, pageIndex + 1];

    for (int i = 0; i < videoFiles.length; i++) {
      if (!toKeep.contains(i) && _controllerCache.containsKey(i)) {
        _controllerCache[i]?.dispose();
        _controllerCache.remove(i);
      }
    }

    for (int i in toKeep) {
      if (i >= 0 && i < videoFiles.length && !_controllerCache.containsKey(i)) {
        final controller = VideoPlayerController.file(videoFiles[i]);
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(1.0);
        _controllerCache[i] = controller;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());
    if (videoFiles.isEmpty) return Center(child: Text("No videos found."));

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: videoFiles.length,
      onPageChanged: (index) {
        _currentPage = index;
        _preloadControllers(index);
        for (var entry in _controllerCache.entries) {
          if (entry.key == index) {
            if (entry.value.value.isInitialized) {
              entry.value.play();
            } else {
              entry.value.addListener(() {
                if (entry.value.value.isInitialized) {
                  entry.value.play();
                }
              });
            }
          } else {
            entry.value.pause();
          }
        }
      },
      itemBuilder: (context, index) {
        final file = videoFiles[index];
        final meta = videoMetadata[file.path.split('/').last]!;
        final controller = _controllerCache[index];

        if (controller == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ReelItem(
          key: ValueKey(file.path),
          file: file,
          metadata: meta,
          controller: controller,
        );
      },
    );
  }
}

class ReelItem extends StatefulWidget {
  final File file;
  final VideoMeta metadata;
  final VideoPlayerController controller;

  const ReelItem({
    super.key,
    required this.file,
    required this.metadata,
    required this.controller,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  bool _isMuted = false;
  Uint8List? _thumbnail;

  Future<void> _generateThumbnail() async {
    final thumb = await VideoThumbnail.thumbnailData(
      video: widget.file.path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
    if (mounted) {
      setState(() {
        _thumbnail = thumb;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiked = widget.metadata.liked;
    final bool isFollowed = widget.metadata.follow;
    final String username = widget.metadata.creator;
    final List<Comment> comments = widget.metadata.comments;

    if (!widget.controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Static blurred background
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
                          Colors.black.withValues(alpha: 0.5),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  color: Colors.black,
                ), // fallback until thumbnail is ready
        ),
        // Foreground video (in 9:16)
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isMuted = !_isMuted;
                widget.controller.setVolume(_isMuted ? 0.0 : 1.0);
              });
            },
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: VideoPlayer(widget.controller),
            ),
          ),
        ),

        _buildOverlay(username, isLiked, isFollowed, comments, context),
      ],
    );
  }

  Widget buildAvatar(String username) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(child: Blockies(seed: username, size: 8)),
    );
  }

  Widget _buildOverlay(
    String username,
    bool isLiked,
    bool isFollowed,
    List<Comment> comments,
    BuildContext context,
  ) {
    bool followed = isFollowed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final videoWidth = screenHeight * (9 / 16);
        final horizontalPadding = ((screenWidth - videoWidth) / 2).clamp(
          0,
          screenWidth,
        );

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
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                      size: 42,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.comment, size: 42),
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
                                  itemCount: comments.length,
                                  itemBuilder: (_, i) {
                                    final comment = comments[i];
                                    return ListTile(
                                      leading: buildAvatar(comment.user),
                                      title: Text(comment.user),
                                      subtitle: Text(comment.comment),
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
                    icon: const Icon(Icons.share, size: 42),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, size: 42),
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
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: buildAvatar(username),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 12),
                      followed
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
          ],
        );
      },
    );
  }
}
