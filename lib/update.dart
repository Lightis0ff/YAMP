import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yamp/main.dart';
import 'package:yamp/prefs.dart';
import 'package:yamp/utils.dart';

// ======================================================
//   Kindly taken from the app_updater package because
//    it didn't pair well with other package versions.
//        https://pub.dev/packages/app_updater/
// ======================================================

const githubOwner = 'Lightis0ff';
const githubRepo = 'yamp';

const String? githubToken = null;
const githubIncludePrereleases = false;

/// Compare two version strings (returns true if latestVersion is newer)
bool _isNewerVersion(String currentVersion, String latestVersion) {
  try {
    final current = Version.parse(currentVersion);
    final latest = Version.parse(latestVersion);

    return latest > current;
  } catch (e) {
    return currentVersion != latestVersion;
  }
}

/// Result of version check containing version info, update URL, and metadata.
class UpdateInfo {
  /// The current installed version of the app
  final String currentVersion;

  /// The latest available version from the store/endpoint (null if check failed)
  final String? latestVersion;

  /// The URL to update/download the app (null if not available)
  final String? updateUrl;

  /// Whether an update is available
  final bool updateAvailable;

  /// Release notes or changelog for the new version (if available)
  final String? releaseNotes;

  /// Release date of the new version (if available)
  final DateTime? releaseDate;

  /// Size of the update in bytes (if available)
  final int? updateSizeBytes;

  /// Creates an UpdateInfo instance with version and update details.
  UpdateInfo({
    required this.currentVersion,
    this.latestVersion,
    this.updateUrl,
    required this.updateAvailable,
    this.releaseNotes,
    this.releaseDate,
    this.updateSizeBytes,
  });

  @override
  String toString() {
    return 'UpdateInfo(currentVersion: $currentVersion, latestVersion: $latestVersion, '
        'updateUrl: $updateUrl, updateAvailable: $updateAvailable, '
        'releaseNotes: ${releaseNotes != null ? "[provided]" : "null"})';
  }

  /// Creates a copy of this UpdateInfo with the given fields replaced.
  UpdateInfo copyWith({
    String? currentVersion,
    String? latestVersion,
    String? updateUrl,
    bool? updateAvailable,
    String? releaseNotes,
    DateTime? releaseDate,
    int? updateSizeBytes,
  }) {
    return UpdateInfo(
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      updateUrl: updateUrl ?? this.updateUrl,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      releaseDate: releaseDate ?? this.releaseDate,
      updateSizeBytes: updateSizeBytes ?? this.updateSizeBytes,
    );
  }
}

class GitHubRelease {
  /// The tag name (usually version number like 'v1.0.0' or '1.0.0')
  final String tagName;

  /// The release name/title
  final String name;

  /// Release notes body (markdown)
  final String body;

  /// Whether this is a prerelease
  final bool prerelease;

  /// Whether this is a draft release
  final bool draft;

  /// When the release was published
  final DateTime publishedAt;

  /// Direct download URL for the release assets
  final String? downloadUrl;

  /// URL to the release page on GitHub
  final String htmlUrl;

  /// Creates a GitHubRelease from parsed data.
  GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.prerelease,
    required this.draft,
    required this.publishedAt,
    this.downloadUrl,
    required this.htmlUrl,
  });

  /// Parses version from tag name (removes 'v' prefix if present)
  String get version {
    if (tagName.toLowerCase().startsWith('v')) {
      return tagName.substring(1);
    }
    return tagName;
  }

  /// Creates a GitHubRelease from JSON API response.
  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    String? downloadUrl;
    final assets = json['assets'] as List?;
    if (assets != null && assets.isNotEmpty) {
      downloadUrl = assets[0]['browser_download_url'];
    }

    return GitHubRelease(
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      prerelease: json['prerelease'] ?? false,
      draft: json['draft'] ?? false,
      publishedAt: DateTime.parse(
        json['published_at'] ?? DateTime.now().toIso8601String(),
      ),
      downloadUrl: downloadUrl,
      htmlUrl: json['html_url'] ?? '',
    );
  }
}

/// Build merged headers for GitHub API requests.
Map<String, String> _buildGitHubHeaders() {
  final headers = <String, String>{'Accept': 'application/vnd.github.v3+json'};

  // Apply token-based auth if provided
  if (githubToken != null) {
    headers['Authorization'] = 'token $githubToken';
  }

  return headers;
}

/// Fetch latest release from GitHub Releases.
Future<GitHubRelease?> _getLatestGitHubRelease() async {
  try {
    final url =
        'https://api.github.com/repos/$githubOwner/$githubRepo/releases';
    final response = await http.get(
      Uri.parse(url),
      headers: _buildGitHubHeaders(),
    );

    if (response.statusCode == 200) {
      final releases = jsonDecode(response.body) as List;
      for (final release in releases) {
        final githubRelease = GitHubRelease.fromJson(release);
        // Skip drafts
        if (githubRelease.draft) continue;
        // Skip prereleases unless configured to include them
        if (githubRelease.prerelease && !githubIncludePrereleases) {
          continue;
        }
        return githubRelease;
      }
    }
  } catch (e) {
    log('Error fetching GitHub releases: $e');
  }
  return null;
}

Future<PackageInfo> _getPackageInfo() async {
  return await PackageInfo.fromPlatform();
}

Future<String> _getCurrentVersion() async {
  final packageInfo = await _getPackageInfo();
  return packageInfo.version;
}

Future<UpdateInfo> checkForUpdate() async {
  final currentVersion = await _getCurrentVersion();
  String? latestVersion;
  String? updateUrl;
  String? releaseNotes;
  DateTime? releaseDate;
  int? updateSizeBytes;

  try {
    final release = await _getLatestGitHubRelease();
    if (release != null) {
      latestVersion = release.version;
      updateUrl = release.downloadUrl ?? release.htmlUrl;
      releaseNotes = release.body;
      releaseDate = release.publishedAt;
    }

    final updateAvailable =
        latestVersion != null && _isNewerVersion(currentVersion, latestVersion);

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      updateUrl: updateUrl,
      updateAvailable: updateAvailable,
      releaseNotes: releaseNotes,
      releaseDate: releaseDate,
      updateSizeBytes: updateSizeBytes,
    );
  } catch (e) {
    debugPrint('Error checking for update: $e');

    return UpdateInfo(currentVersion: currentVersion, updateAvailable: false);
  }
}

Future<void> showUpdateModal(BuildContext context, UpdateInfo updateInfo) {
  return showDialog(
    context: context,
    builder: (context) => styledAlertDialog(
      context,
      title: Column(
        crossAxisAlignment: .start,
        spacing: 5,
        children: [
          Row(
            spacing: 5,
            children: [
              Icon(Symbols.system_update_alt),
              Text('Update available'),
            ],
          ),
          SelectableText(
            'Your version: ${updateInfo.currentVersion}, new version: ${updateInfo.latestVersion}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          if (updateInfo.releaseNotes != null) ...[
            Text(
              'Release notes:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  updateInfo.releaseNotes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            SizedBox(height: 8),
          ],
          InkWell(
            onTap: () async {
              if (updateInfo.latestVersion == null) return;
              await Prefs.setSkippedVersion(updateInfo.latestVersion!);
              Navigator.of(context).pop();
            },
            customBorder: RoundedRectangleBorder(borderRadius: .circular(5)),
            child: Row(
              mainAxisSize: .min,
              spacing: 3,
              children: [
                Icon(Symbols.skip_next, fill: 1, color: mainColor),
                Text('Skip this version', style: TextStyle(color: mainColor)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        actionOutlineButton(
          onPressed: () => Navigator.of(context).pop(),
          text: 'Later',
        ),
        actionElevatedButton(
          onPressed: () async {
            if (updateInfo.updateUrl == null) return;
            await launchUrl(Uri.parse(updateInfo.updateUrl!));
            Navigator.of(context).pop();
          },
          text: 'Download',
          icon: Symbols.open_in_new,
          iconAlignment: .end,
        ),
      ],
    ),
  );
}

Future<void> showUpdateNotNeededModal(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return styledAlertDialog(
        context,
        title: Row(
          spacing: 5,
          children: [Icon(Symbols.check), Text('No update needed')],
        ),
        content: Text(
          'You already have the latest version of YAMP',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          actionElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            text: 'Close',
          ),
        ],
      );
    },
  );
}
