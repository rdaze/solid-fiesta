import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/app_constants.dart';
import '../models/video_meta.dart';

class ReelsLoader {
  static Future<Map<String, VideoMeta>> loadVideoMetadata(
    String profile,
  ) async {
    final jsonStr = await rootBundle.loadString(
      AppConstants.reelsMetadataPath(profile),
    );
    final jsonData = json.decode(jsonStr);
    final List videos = jsonData['videos'];
    final metadata = {
      for (var v in videos) v['filename'] as String: VideoMeta.fromJson(v),
    };
    return metadata;
  }

  static Future<List<String>> loadVideoFilenamesFromMetadata(
    String profile,
  ) async {
    final jsonStr = await rootBundle.loadString(
      AppConstants.reelsMetadataPath(profile),
    );
    final jsonData = json.decode(jsonStr);
    final List videos = jsonData['videos'];
    return videos.map((v) => v['filename'] as String).toList();
  }

  static Future<List<File>> copyAssetVideosToLocal(String profile) async {
    final filenames = await loadVideoFilenamesFromMetadata(profile);
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/videos');
    if (!videoDir.existsSync()) {
      videoDir.createSync(recursive: true);
    }

    List<File> copiedFiles = [];
    for (final name in filenames) {
      final assetPath = '${AppConstants.videosDirForProfile(profile)}$name';
      final localPath = '${videoDir.path}/$name';
      final byteData = await rootBundle.load(assetPath);
      final file = File(localPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      copiedFiles.add(file);
    }
    return copiedFiles;
  }
}
