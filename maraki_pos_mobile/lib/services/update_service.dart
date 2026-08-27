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
  static const String currentAppVersion = '2.7.0';
  static const int currentBuildNumber = 9;
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

  /// Download APK to local storage and trigger native installer
  /// Uses rock-solid chunked streaming with HTTP Range auto-resume and multi-retry
  static Future<bool> downloadAndInstallApk(
    String apkUrl, {
    required void Function(int progress) onProgress,
    required void Function(String error) onError,
    void Function(int receivedBytes)? onBytesReceived,
    void Function(String statusMessage)? onStatusChanged,
  }) async {
    try {
      if (apkUrl.isEmpty) {
        onError('የማዘመኛ አድራሻ (APK URL) አልተገኘም።');
        return false;
      }

      // 1. Resolve Target Directory (Try external files first, then temp/cache)
      Directory? targetDir;
      try {
        targetDir = await getExternalStorageDirectory();
      } catch (_) {}
      targetDir ??= await getTemporaryDirectory();

      final File apkFile = File('${targetDir.path}/maraki_pos_update.apk');

      // 2. Candidate URLs (Primary + Fallback mirrors)
      final List<String> candidateUrls = [
        apkUrl.trim(),
        if (!apkUrl.contains('releases/download'))
          'https://github.com/Samiassaye-21/Budget-system/releases/download/v2.7.0/maraki_pos_arm64.apk',
        'https://raw.githubusercontent.com/Samiassaye-21/Budget-system/main/public/maraki_pos_arm64.apk',
      ];

      // Remove duplicates
      final uniqueUrls = candidateUrls.toSet().toList();

      bool downloadSuccess = false;
      String lastErrorMessage = '';

      for (final currentUrl in uniqueUrls) {
        debugPrint('Attempting download from: $currentUrl');
        downloadSuccess = await _downloadWithAutoResume(
          url: currentUrl,
          apkFile: apkFile,
          onProgress: onProgress,
          onBytesReceived: onBytesReceived,
          onStatusChanged: onStatusChanged,
          onErrorDetails: (msg) {
            lastErrorMessage = msg;
          },
        );

        if (downloadSuccess && await apkFile.exists() && await apkFile.length() > 5000000) {
          break; // Successfully downloaded valid APK (> 5MB)
        }
      }

      if (!downloadSuccess || !await apkFile.exists() || await apkFile.length() <= 5000000) {
        onError(lastErrorMessage.isNotEmpty
            ? lastErrorMessage
            : 'ፋይሉን ማውረድ አልተቻለም። እባክዎ የበይነመረብ (Internet) ግንኙነትዎን ያረጋግጡ።');
        return false;
      }

      // 3. Check Unknown Apps Install Permission on Android
      if (!kIsWeb && Platform.isAndroid) {
        onStatusChanged?.call('የመጫኛ ፍቃድ በማረጋገጥ ላይ...');
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      }

      // 4. Trigger Native Installer via OpenFilex
      onStatusChanged?.call('መጫኛውን በመክፈት ላይ...');
      final result = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('OpenFilex result: ${result.type} - ${result.message}');
      if (result.type != ResultType.done) {
        if (result.message.toLowerCase().contains('permission') ||
            result.message.toLowerCase().contains('security') ||
            result.type == ResultType.permissionDenied) {
          await openAppSettings();
          onError('እባክዎ በስልክዎ Settings ውስጥ "Install Unknown Apps" ፍቃድ ይስጡ።');
        } else {
          onError('መጫኛውን መክፈት አልተቻለም: ${result.message}');
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('downloadAndInstallApk Error: $e');
      onError('የማዘመን ስህተት: $e');
      return false;
    }
  }

  /// Downloads file with automatic byte range resume, redirect handling, and multi-retries
  static Future<bool> _downloadWithAutoResume({
    required String url,
    required File apkFile,
    required void Function(int progress) onProgress,
    void Function(int receivedBytes)? onBytesReceived,
    void Function(String statusMessage)? onStatusChanged,
    void Function(String error)? onErrorDetails,
  }) async {
    const int maxRetries = 8;
    int attempt = 0;
    int expectedTotalBytes = 0;

    // Fresh start or clean corrupt file
    if (await apkFile.exists()) {
      try {
        await apkFile.delete();
      } catch (_) {}
    }

    while (attempt < maxRetries) {
      attempt++;
      HttpClient? client;
      IOSink? sink;

      try {
        int existingBytes = 0;
        if (await apkFile.exists()) {
          existingBytes = await apkFile.length();
        }

        // If we already know expectedTotalBytes and we have all bytes, done!
        if (expectedTotalBytes > 0 && existingBytes >= expectedTotalBytes) {
          onProgress(100);
          onBytesReceived?.call(existingBytes);
          return true;
        }

        client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 15)
          ..idleTimeout = const Duration(seconds: 30)
          ..autoUncompress = false; // Keep exact binary byte length

        String resolvedUrl = url;
        HttpClientResponse? response;
        int redirectCount = 0;

        // Manual redirect follower to support cross-domain/S3 redirects with Range header
        while (redirectCount < 8) {
          final request = await client.getUrl(Uri.parse(resolvedUrl));
          request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Linux; Android 14; Mobile) MarakiPOS/2.7.0');
          request.headers.set(HttpHeaders.acceptHeader, '*/*');
          request.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
          request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

          if (existingBytes > 0) {
            request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
            debugPrint('Resuming download from byte: $existingBytes');
          }

          response = await request.close();

          if (response.statusCode >= 300 && response.statusCode < 400) {
            final location = response.headers.value(HttpHeaders.locationHeader);
            if (location != null && location.isNotEmpty) {
              resolvedUrl = Uri.parse(resolvedUrl).resolve(location).toString();
              redirectCount++;
              continue;
            }
          }
          break;
        }

        if (response == null) {
          throw HttpException('ምንም ምላሽ አልተገኘም (No response from server)');
        }

        final statusCode = response.statusCode;

        if (statusCode == HttpStatus.requestedRangeNotSatisfiable) {
          // 416: Possibly already complete
          if (existingBytes > 5000000) {
            onProgress(100);
            return true;
          } else {
            // Corrupted range, delete and restart
            if (await apkFile.exists()) await apkFile.delete();
            existingBytes = 0;
            continue;
          }
        }

        if (statusCode != HttpStatus.ok && statusCode != HttpStatus.partialContent) {
          onErrorDetails?.call('ሰርቨሩ አልተቀበለም (HTTP $statusCode)');
          return false;
        }

        bool isPartial = statusCode == HttpStatus.partialContent;

        if (!isPartial && existingBytes > 0) {
          // Server returned full file instead of partial range, reset local file
          if (await apkFile.exists()) await apkFile.delete();
          existingBytes = 0;
        }

        final contentLength = response.contentLength;
        if (contentLength > 0) {
          expectedTotalBytes = isPartial ? (existingBytes + contentLength) : contentLength;
        }

        sink = apkFile.openWrite(mode: isPartial ? FileMode.append : FileMode.write);
        int currentBytes = existingBytes;

        await for (final List<int> chunk in response) {
          sink.add(chunk);
          currentBytes += chunk.length;
          onBytesReceived?.call(currentBytes);

          if (expectedTotalBytes > 0) {
            final progress = ((currentBytes / expectedTotalBytes) * 100).toInt();
            onProgress(progress.clamp(0, 100));
          }
        }

        await sink.flush();
        await sink.close();
        sink = null;

        client.close();
        client = null;

        // Check if download completed
        final finalFileLength = await apkFile.length();
        if (expectedTotalBytes > 0 && finalFileLength >= expectedTotalBytes) {
          onProgress(100);
          onBytesReceived?.call(finalFileLength);
          return true;
        } else if (expectedTotalBytes == 0 && finalFileLength > 5000000) {
          onProgress(100);
          return true;
        }

        // If file ended prematurely without full bytes, retry from current offset
        debugPrint('Download connection closed prematurely at $finalFileLength bytes. Retrying ($attempt/$maxRetries)...');
        onStatusChanged?.call('ግንኙነቱ ተቋርጦ ነበር፤ ከቆመበት በማስቀጠል ላይ (ሙከራ $attempt)...');
        await Future.delayed(const Duration(milliseconds: 1500));
      } catch (e) {
        debugPrint('Download attempt $attempt error: $e');
        try {
          await sink?.flush();
          await sink?.close();
        } catch (_) {}
        try {
          client?.close(force: true);
        } catch (_) {}

        if (attempt >= maxRetries) {
          onErrorDetails?.call('የኔትወርክ ግንኙነት ተቋርጧል ($e)። እባክዎ የበይነመረብ መስመርዎን ያረጋግጡ።');
          return false;
        }

        onStatusChanged?.call('ኔትወርክ ተቋርጧል፤ በድጋሚ በማገናኘት ላይ (ሙከራ $attempt/$maxRetries)...');
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }
    }

    return false;
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

