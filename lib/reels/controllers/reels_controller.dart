import 'dart:io';
import 'package:video_player/video_player.dart';

class ReelsController {
  final Map<int, VideoPlayerController> _cache = {};
  bool _isMuted = true;
  List<File> _files = [];

  bool get isMuted => _isMuted;

  Future<void> init(List<File> files, {bool muted = true}) async {
    _files = files;
    _isMuted = muted;
    if (_files.isNotEmpty) {
      await _preloadAround(0);
    }
  }

  Future<void> _preloadAround(int pageIndex) async {
    final toKeep = {pageIndex - 1, pageIndex, pageIndex + 1};

    // dispose controllers not in the window
    final keys = _cache.keys.toList();
    for (final k in keys) {
      if (!toKeep.contains(k)) {
        _cache[k]?.dispose();
        _cache.remove(k);
      }
    }

    // create missing controllers in the window
    for (final i in toKeep) {
      if (i >= 0 && i < _files.length && !_cache.containsKey(i)) {
        final c = VideoPlayerController.file(_files[i]);
        await c.initialize();
        c.setLooping(true);
        c.setVolume(_isMuted ? 0.0 : 1.0);
        _cache[i] = c;
      }
    }
  }

  VideoPlayerController? controllerFor(int index) => _cache[index];

  Future<void> onPageChanged(int index) async {
    await _preloadAround(index);
    _cache.forEach((i, c) {
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
    });
  }

  void setMuted(bool value) {
    _isMuted = value;
    for (final c in _cache.values) {
      c.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  void dispose() {
    for (final c in _cache.values) {
      c.dispose();
    }
    _cache.clear();
  }
}
