import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

Future<List<File>> copyAssetVideosToLocal() async {
  final filenames = [
    'y_DHL_y.mp4',
    'y_OutDoorGang_n.mp4',
    'n_Doggo_n.mp4',
  ];

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
  const MyApp({Key? key}) : super(key: key);

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
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  List<File> videoFiles = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    copyAssetVideosToLocal().then((files) {
      setState(() {
        videoFiles = files;
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
      itemCount: videoFiles.length,
      itemBuilder: (context, index) {
        return ReelItem(file: videoFiles[index]);
      },
    );
  }
}

class ReelItem extends StatefulWidget {
  final File file;

  const ReelItem({Key? key, required this.file}) : super(key: key);

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late VideoPlayerController _controller;
  late bool _isLiked;
  late String _username;
  late bool _isFollowed;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    final fileName = widget.file.path.split('/').last.replaceAll('.mp4', '');
    _isLiked = fileName.startsWith('liked_');

    final parts = fileName.split('_');
    if (parts.length >= 3) {
      _isLiked = parts[0] == 'y';
      _username = parts.sublist(1, parts.length - 1).join('_');
      _isFollowed = parts.last == 'y';
    } else {
      _isLiked = false;
      _username = 'unknown';
      _isFollowed = false;
    }

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
        // Right-side: Like, Comment, Share
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
                  // Do nothing; visual only
                },
              ),
              SizedBox(height: 16),
              IconButton(
                icon: Icon(Icons.comment, size: 32),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Container(
                      height: 300,
                      child: Center(child: Text("Comments (Coming Soon)")),
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

        // Left-side: Username + Follow
        Positioned(
          left: 16,
          bottom: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '@$_username',
                style: TextStyle(fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                decoration: TextDecoration.none),
              ),
              const SizedBox(width: 12),
              _isFollowed
                  ? ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isFollowed = !_isFollowed;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Followed',
                        style: TextStyle(color: Colors.black)
                        ),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isFollowed = !_isFollowed;
                        });
                      },
                      child: Text('Follow'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              )
            : Center(child: CircularProgressIndicator()),
        _buildOverlay(),
      ],
    );
  }
}
