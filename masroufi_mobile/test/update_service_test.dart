import 'package:flutter_test/flutter_test.dart';
import 'package:masroufi_mobile/core/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isUpdateAvailable correctly checks build numbers', () {
      final infoNewer = AppUpdateInfo(
        appName: 'مصروفي',
        latestVersion: '1.0.5',
        latestBuildNumber: UpdateService.currentBuildNumber + 1,
        releaseNotes: 'تحديث تجريبي',
        downloadUrl: 'https://masroufi.msulimancode.com/masroufi.apk',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=ly.masroufi.masroufi_mobile',
      );

      final infoOlder = AppUpdateInfo(
        appName: 'مصروفي',
        latestVersion: '1.0.1',
        latestBuildNumber: UpdateService.currentBuildNumber - 1,
        releaseNotes: 'إصدار قديم',
        downloadUrl: 'https://masroufi.msulimancode.com/masroufi.apk',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=ly.masroufi.masroufi_mobile',
      );

      expect(UpdateService.isUpdateAvailable(infoNewer), isTrue);
      expect(UpdateService.isUpdateAvailable(infoOlder), isFalse);
    });

    test('remindLater saves timestamp and shouldPromptUpdate respects 24h postponement', () async {
      final newerBuild = UpdateService.currentBuildNumber + 1;
      final info = AppUpdateInfo(
        appName: 'مصروفي',
        latestVersion: '1.0.5',
        latestBuildNumber: newerBuild,
        releaseNotes: 'ملاحظات التحديث',
        downloadUrl: 'https://masroufi.msulimancode.com/masroufi.apk',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=ly.masroufi.masroufi_mobile',
      );

      expect(await UpdateService.shouldPromptUpdate(info), isTrue);

      await UpdateService.remindLater(newerBuild);

      expect(await UpdateService.shouldPromptUpdate(info), isFalse);

      final forceInfo = AppUpdateInfo(
        appName: 'مصروفي',
        latestVersion: '1.0.5',
        latestBuildNumber: newerBuild,
        releaseNotes: 'ملاحظات التحديث الإجباري',
        downloadUrl: 'https://masroufi.msulimancode.com/masroufi.apk',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=ly.masroufi.masroufi_mobile',
        forceUpdate: true,
      );
      expect(await UpdateService.shouldPromptUpdate(forceInfo), isTrue);
    });

    test('AppUpdateInfo model parsing from JSON', () {
      final json = {
        'app_name': 'مصروفي',
        'latest_version': '1.0.4',
        'latest_build_number': 5,
        'release_notes': 'تحسينات',
        'download_url': 'https://masroufi.msulimancode.com/masroufi.apk',
        'play_store_url': 'https://play.google.com',
        'force_update': false,
      };

      final parsed = AppUpdateInfo.fromJson(json);
      expect(parsed.appName, 'مصروفي');
      expect(parsed.latestVersion, '1.0.4');
      expect(parsed.latestBuildNumber, 5);
      expect(parsed.forceUpdate, isFalse);
    });
  });
}
