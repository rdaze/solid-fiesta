import 'dart:io';
import 'package:flutter/material.dart';
import '../../app/app_constants.dart';
import '../controllers/reels_controller.dart';
import '../models/video_meta.dart';
import '../services/reels_loader.dart';
import '../widgets/reel_item.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => ReelsPageState();
}

class ReelsPageState extends State<ReelsPage> {
  final ReelsController _reels = ReelsController();
  final PageController _pageController = PageController();

  List<File> _videoFiles = [];
  Map<String, VideoMeta> _metadata = {};
  bool _loading = true;
  int _currentPage = 0;

  bool get _isMuted => _reels.isMuted;

  void setMuted(bool value) {
    setState(() => _reels.setMuted(value));
    final vol = value ? 0.0 : 1.0;
    for (var i = 0; i < _videoFiles.length; i++) {
      _reels.controllerFor(i)?.setVolume(vol);
    }
  }

  void pauseAll() {
    for (var i = 0; i < _videoFiles.length; i++) {
      final c = _reels.controllerFor(i);
      c?.pause();
    }
  }

  void playCurrent() {
    final c = _reels.controllerFor(_currentPage);
    if (c == null) return;
    if (c.value.isInitialized) {
      c.play();
    } else {
      c.addListener(() {
        if (c.value.isInitialized) {
          c.play();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final files = await ReelsLoader.copyAssetVideosToLocal(
      AppConstants.profileName,
    );
    final meta = await ReelsLoader.loadVideoMetadata(AppConstants.profileName);

    final filtered = files
        .where((f) => meta.containsKey(f.path.split('/').last))
        .toList();

    await _reels.init(filtered, muted: true);

    setState(() {
      _videoFiles = filtered;
      _metadata = meta;
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => playCurrent());
  }

  @override
  void dispose() {
    _reels.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_videoFiles.isEmpty)
      return const Center(child: Text('No videos found.'));

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: _videoFiles.length,
      onPageChanged: (index) {
        _currentPage = index;
        _reels.onPageChanged(index); // keep your existing controller logic
        // hard-ensure only the current plays
        for (var i = 0; i < _videoFiles.length; i++) {
          final c = _reels.controllerFor(i);
          if (c == null) continue;
          if (i == index) {
            if (c.value.isInitialized) {
              c.play();
            } else {
              c.addListener(() {
                if (c.value.isInitialized) c.play();
              });
            }
          } else {
            c.pause();
          }
        }
      },
      itemBuilder: (context, index) {
        final file = _videoFiles[index];
        final name = file.path.split('/').last;
        final meta = _metadata[name]!;
        final controller = _reels.controllerFor(index);
        if (controller == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ReelItem(
          key: ValueKey(file.path),
          username: meta.creator,
          isLiked: meta.liked,
          isFollowed: meta.follow,
          comments: meta.comments,
          filePath: file.path,
          controller: controller,
          isMuted: _isMuted,
          onToggleMute: () => setMuted(!_isMuted),
        );
      },
    );
  }
}
