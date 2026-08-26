import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  static const String currentAppVersion = '2.6.2';
  static const int currentBuildNumber = 5;
  static const String androidAppId = 'com.marakipos.maraki_pos_mobile';

  // Remote Manifest Endpoint
  static const String defaultUpdateManifestUrl =
      'https://raw.githubusercontent.com/Samiassaye-21/Budget-system/main/app_version.json';

  /// Check remote version with cache buster
  static Future<AppUpdateInfo> checkForUpdate({String? customUrl}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final manifestUrl = customUrl ?? '$defaultUpdateManifestUrl?t=$timestamp';

    try {
      final response = await http
          .get(
            Uri.parse(manifestUrl),
            headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
          )
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

    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: currentAppVersion,
      latestVersion: currentAppVersion,
      releaseNotes: 'ሲስተምዎ በቅርቡ የተሻሻለው አዲስ ስሪት ላይ ነው (Up to date)',
      apkUrl: '',
    );
  }

  /// Check & Request Install Unknown Apps permission
  static Future<bool> ensureInstallPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) return true;

    final result = await Permission.requestInstallPackages.request();
    return result.isGranted;
  }

  /// Download APK to external storage and trigger native installer
  static Future<bool> downloadAndInstallApk(
    String apkUrl, {
    required void Function(int progress) onProgress,
    required void Function(String error) onError,
    void Function(int receivedBytes)? onBytesReceived,
  }) async {
    try {
      // 1. Verify Permission BEFORE download
      final hasPerm = await ensureInstallPermission();
      if (!hasPerm) {
        onError('እባክዎ በስልክዎ Settings ውስጥ "Install Unknown Apps" ፍቃድ ይስጡ።');
        return false;
      }

      // 2. Resolve External Files Directory (Accessible by FileProvider)
      final Directory? externalDir = await getExternalStorageDirectory();
      final Directory targetDir = externalDir ?? await getTemporaryDirectory();
      final File apkFile = File('${targetDir.path}/maraki_pos_update.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      // 3. Download APK with Stream progress
      //    Use http.Client with redirects (GitHub releases return 302→CDN)
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(apkUrl))
        ..followRedirects = true
        ..maxRedirects = 10;
      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        onError('ፋይሉን ማውረድ አልተቻለም (HTTP ${response.statusCode})');
        return false;
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = apkFile.openWrite();

      await response.stream.listen((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        // Always report raw bytes so UI can show MB even without Content-Length
        onBytesReceived?.call(receivedBytes);
        if (totalBytes > 0) {
          final progress = ((receivedBytes / totalBytes) * 100).toInt();
          onProgress(progress.clamp(0, 100));
        }
      }).asFuture();

      await sink.flush();
      await sink.close();
      client.close();

      // 4. Verify file exists and is not empty
      if (!await apkFile.exists() || await apkFile.length() <= 0) {
        onError('የወረደው የ APK ፋይል ባዶ ነው ወይም አልተገኘም።');
        return false;
      }

      // 5. Trigger Native Installer via OpenFilex (Android v2 embedding FileProvider)
      final result = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('OpenFilex result: ${result.type} - ${result.message}');
      if (result.type != ResultType.done) {
        onError('መጫኛውን መክፈት አልተቻለም: ${result.message}\nእባክዎ "Install unknown apps" ፍቃድ መብራቱን ያረጋግጡ።');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('downloadAndInstallApk Error: $e');
      onError('የማዘመን ስህተት: $e\nእባክዎ "Install unknown apps" ፍቃድ መብራቱን ያረጋግጡ።');
      return false;
    }
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
}
