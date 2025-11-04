import 'package:flutter/services.dart';

class AssetUtils {
  static Future<String> loadString(String path) async =>
      rootBundle.loadString(path);
}
