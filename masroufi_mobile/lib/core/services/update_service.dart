import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/widgets/update_dialog.dart';

class AppUpdateInfo {
  final String appName;
  final String latestVersion;
  final int latestBuildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final String playStoreUrl;
  final bool forceUpdate;

  const AppUpdateInfo({
    required this.appName,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.playStoreUrl,
    this.forceUpdate = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      appName: json['app_name'] as String? ?? 'مصروفي',
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      latestBuildNumber: (json['latest_build_number'] as num?)?.toInt() ?? 1,
      releaseNotes: json['release_notes'] as String? ?? 'تحسينات وإصلاحات عامة في التطبيق.',
      downloadUrl: json['download_url'] as String? ?? 'https://masroufi.msulimancode.com/masroufi.apk',
      playStoreUrl: json['play_store_url'] as String? ?? 'https://play.google.com/store/apps/details?id=ly.masroufi.masroufi_mobile',
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }
}

class UpdateService {
  // Current installed app version & build number
  static const String currentVersion = '1.1.0';
  static const int currentBuildNumber = 11;

  static const MethodChannel _methodChannel = MethodChannel('ly.masroufi.sms/channel');

  static const String _primaryApiUrl = 'https://masroufi-api.msulimancode.com/api/v1/app-settings';
  static const String _fallbackJsonUrl = 'https://masroufi.msulimancode.com/app_settings.json';

  /// Fetches latest update info from server with automatic fallback
  static Future<AppUpdateInfo?> fetchUpdateInfo() async {
    // 1. Try Primary API
    try {
      final response = await http.get(
        Uri.parse(_primaryApiUrl),
        headers: {'Accept': 'application/json', 'User-Agent': 'Masroufi-App'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return AppUpdateInfo.fromJson(data);
        }
      }
    } catch (_) {}

    // 2. Fallback to static JSON
    try {
      final response = await http.get(
        Uri.parse(_fallbackJsonUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return AppUpdateInfo.fromJson(data);
        }
      }
    } catch (_) {}

    return null;
  }

  /// Checks if the fetched update info represents a newer build than currently installed
  static bool isUpdateAvailable(AppUpdateInfo info) {
    return info.latestBuildNumber > currentBuildNumber;
  }

  /// Determines whether the in-app alert should be displayed (respects "ذكرني لاحقاً")
  static Future<bool> shouldPromptUpdate(AppUpdateInfo info) async {
    if (!isUpdateAvailable(info)) return false;
    if (info.forceUpdate) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'masroufi_remind_later_b_${info.latestBuildNumber}';
      final timestamp = prefs.getInt(key);
      if (timestamp != null) {
        final lastRemind = DateTime.fromMillisecondsSinceEpoch(timestamp);
        // Do not prompt again within 24 hours of clicking "ذكرني لاحقاً"
        if (DateTime.now().difference(lastRemind).inHours < 24) {
          return false;
        }
      }
    } catch (_) {}

    return true;
  }

  /// Postpones the update prompt for 24 hours
  static Future<void> remindLater(int buildNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'masroufi_remind_later_b_$buildNumber';
      await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Opens download link natively or in browser
  static Future<void> openDownloadUrl(String url) async {
    if (kIsWeb) {
      return;
    }

    try {
      await _methodChannel.invokeMethod('openUrl', {'url': url});
    } catch (e) {
      debugPrint('Error opening download url: $e');
    }
  }

  /// Silent background check on app launch
  static Future<void> checkAndPromptUpdate(BuildContext context) async {
    // Small delay to ensure the screen finishes loading and transitions
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!context.mounted) return;

    final info = await fetchUpdateInfo();
    if (info == null) {
      debugPrint('[UpdateService] Update check failed or offline.');
      return;
    }

    debugPrint('[UpdateService] Server build: ${info.latestBuildNumber}, Installed build: $currentBuildNumber');
    final shouldPrompt = await shouldPromptUpdate(info);
    if (shouldPrompt && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: !info.forceUpdate,
        builder: (ctx) => UpdateDialog(info: info),
      );
    }
  }

  /// Manual check triggered from Settings screen
  static Future<void> checkForUpdateManual(BuildContext context) async {
    // Show quick loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
      ),
    );

    final info = await fetchUpdateInfo();

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
    }

    if (!context.mounted) return;

    if (info != null && isUpdateAvailable(info)) {
      showDialog(
        context: context,
        barrierDismissible: !info.forceUpdate,
        builder: (ctx) => UpdateDialog(info: info),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Text(
                'أنت تستخدم أحدث إصدار من مصروفي (v$currentVersion)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
