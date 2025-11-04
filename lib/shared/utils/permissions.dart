import 'package:permission_handler/permission_handler.dart';

class PermissionsUtil {
  static Future<bool> ensureStorage() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
}
