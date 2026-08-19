import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String apkUrl;
  final bool isMandatory;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.apkUrl,
    this.isMandatory = false,
  });
}

class UpdateService {
  static const String currentAppVersion = '2.6.0';
  static const int currentBuildNumber = 3;

  // Default endpoint for remote updates. Can be configured to Supabase / GitHub Releases / Custom API
  static const String defaultUpdateManifestUrl =
      'https://raw.githubusercontent.com/Samiassaye-21/Budget-system/main/app_version.json';

  static Future<AppUpdateInfo> checkForUpdate({String? customUrl}) async {
    final manifestUrl = customUrl ?? defaultUpdateManifestUrl;

    try {
      final response = await http
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final String remoteVersion = data['version'] ?? currentAppVersion;
        final int remoteBuild = data['buildNumber'] ?? currentBuildNumber;
        final String apkUrl = data['apkUrl'] ?? '';
        final String notes = data['releaseNotes'] ?? 'አጠቃላይ የሲስተም እና የUI ማሻሻያዎች ተካተዋል';
        final bool force = data['forceUpdate'] ?? false;

        final bool hasNewer = remoteBuild > currentBuildNumber ||
            _isVersionGreater(remoteVersion, currentAppVersion);

        return AppUpdateInfo(
          hasUpdate: hasNewer,
          currentVersion: currentAppVersion,
          latestVersion: remoteVersion,
          releaseNotes: notes,
          apkUrl: apkUrl,
          isMandatory: force,
        );
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }

    // Default if network is offline or no newer version
    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: currentAppVersion,
      latestVersion: currentAppVersion,
      releaseNotes: 'ሲስተምዎ በቅርቡ የተሻሻለው አዲስ ስሪት ላይ ነው (Up to date)',
      apkUrl: '',
    );
  }

  static bool _isVersionGreater(String remote, String current) {
    try {
      final rParts = remote.split('.').map(int.parse).toList();
      final cParts = current.split('.').map(int.parse).toList();
      for (int i = 0; i < rParts.length && i < cParts.length; i++) {
        if (rParts[i] > cParts[i]) return true;
        if (rParts[i] < cParts[i]) return false;
      }
      return rParts.length > cParts.length;
    } catch (_) {
      return false;
    }
  }

  /// Downloads the APK and prompts native Android installer with 1 tap
  static Stream<OtaEvent> executeUpdate(String apkUrl) {
    try {
      return OtaUpdate().execute(
        apkUrl,
        destinationFilename: 'maraki_pos_update.apk',
      );
    } catch (e) {
      debugPrint('OTA execute error: $e');
      rethrow;
    }
  }
}
