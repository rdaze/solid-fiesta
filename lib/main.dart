import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'dart:io';
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

  @override
  void initState() {
    super.initState();

    Future.wait([copyAssetVideosToLocal(), loadVideoMetadata()]).then((
      results,
    ) {
      final List<File> files = results[0] as List<File>;
      final Map<String, VideoMeta> metadata =
          results[1] as Map<String, VideoMeta>;

      setState(() {
        videoFiles = files.where((file) {
          final name = file.path.split('/').last;
          return metadata.containsKey(name);
        }).toList();

        videoMetadata = metadata;
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());
    if (videoFiles.isEmpty) return Center(child: Text("No videos found."));

    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: videoFiles.length,
      itemBuilder: (context, index) {
        final file = videoFiles[index];
        final meta = videoMetadata[file.path.split('/').last]!;

        return ReelItem(file: file, metadata: meta);
      },
    );
  }
}

class ReelItem extends StatefulWidget {
  final File file;
  final VideoMeta metadata;

  const ReelItem({super.key, required this.file, required this.metadata});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late VideoPlayerController _controller;
  late bool _isLiked;
  late bool _isFollowed;
  late String _username;
  late List<Comment> _comments;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();

    final meta = widget.metadata;
    _isLiked = meta.liked;
    _isFollowed = meta.follow;
    _username = meta.creator;
    _comments = meta.comments;

    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.setVolume(1.0);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  // Visual only
                },
              ),
              SizedBox(height: 16),
              IconButton(
                icon: Icon(Icons.comment, size: 32),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (_, i) {
                          final comment = _comments[i];
                          return ListTile(
                            title: Text(comment.user),
                            subtitle: Text(comment.comment),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              IconButton(
                icon: Icon(Icons.share, size: 32),
                onPressed: () {
                  // Visual only
                },
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          bottom: 100,
          child: Row(
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '@$_username',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _isFollowed
                  ? ElevatedButton(
                      onPressed: () => setState(() {
                        _isFollowed = !_isFollowed;
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Followed',
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () => setState(() {
                        _isFollowed = !_isFollowed;
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text('Follow'),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _controller.value.isInitialized
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _isMuted = !_isMuted;
                    _controller.setVolume(_isMuted ? 0.0 : 1.0);
                  });
                },
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : Center(child: CircularProgressIndicator()),
        _buildOverlay(),
      ],
    );
  }
}
