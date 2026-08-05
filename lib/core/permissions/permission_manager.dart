import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../logger/app_logger.dart';

class PermissionManager {
  static const String _tag = 'PermissionManager';

  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      AppLogger.i('Camera permission status: $status', _tag);
      return status.isGranted;
    } catch (e) {
      AppLogger.e('Failed to request camera permission', tag: _tag, error: e);
      return false;
    }
  }

  static Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (SDK 33+), granular media permissions apply.
        // For Android 10+, scoped storage works without broad storage permissions for app documents.
        final photosStatus = await Permission.photos.request();
        if (photosStatus.isGranted) return true;
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      AppLogger.e('Failed to request storage permission', tag: _tag, error: e);
      return false;
    }
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      AppLogger.i('Notification permission status: $status', _tag);
      return status.isGranted;
    } catch (e) {
      AppLogger.e('Failed to request notification permission', tag: _tag, error: e);
      return false;
    }
  }

  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}
