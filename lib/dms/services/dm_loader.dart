import 'dart:convert';
import 'package:flutter/services.dart';
import '../../app/app_constants.dart';
import '../models/chat_thread.dart';

class DmLoader {
  static Future<List<ChatThread>> loadThreadsForProfile(String profile) async {
    final path = AppConstants.dmsMetadataPath(profile);
    final jsonStr = await rootBundle.loadString(path);
    final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
    final threads = (jsonData['threads'] as List<dynamic>? ?? [])
        .map((e) => ChatThread.fromJson(e as Map<String, dynamic>))
        .toList();
    return threads;
  }
}
