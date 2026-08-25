import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static final _prefs = SharedPreferencesAsync();

  static const _defaultAudioDeviceKey = 'defaultAudioDevice';
  static const _showFForwardButtonKey = 'showFForwardButton';
  static const _fastForwardSpeedKey = 'fastForwardSpeed';
  static const _fastForwardPitchKey = 'fastForwardPitch';

  static const _customTitleBarKey = 'customTitleBar';

  static const _autoCheckUpdatesKey = 'autoCheckUpdates';
  static const _skippedVersionKey = 'skippedVersion';

  static Future<void> setDefaultAudioDevice(String name) async =>
      await _prefs.setString(_defaultAudioDeviceKey, name);
  static Future<void> setShowFForwardButton(bool value) async =>
      await _prefs.setBool(_showFForwardButtonKey, value);
  static Future<void> setFastForwardSpeed(double speed) async =>
      await _prefs.setDouble(_fastForwardSpeedKey, speed);
  static Future<void> setFastForwardPitch(double pitch) async =>
      await _prefs.setDouble(_fastForwardPitchKey, pitch);

  static Future<void> setCustomTitlebar(bool value) async =>
      await _prefs.setBool(_customTitleBarKey, value);

  static Future<void> setAutoCheckUpdates(bool value) async =>
      await _prefs.setBool(_autoCheckUpdatesKey, value);
  static Future<void> setSkippedVersion(String version) async =>
      await _prefs.setString(_skippedVersionKey, version);

  // ------------ set ↑ ------------ get ↓ -----------------
  static Future<String?> getDefaultAudioDevice() async =>
      await _prefs.getString(_defaultAudioDeviceKey);
  static Future<bool?> getShowFForwardButton() async =>
      await _prefs.getBool(_showFForwardButtonKey);
  static Future<double?> getFastForwardSpeed() async =>
      await _prefs.getDouble(_fastForwardSpeedKey);
  static Future<double?> getFastForwardPitch() async =>
      await _prefs.getDouble(_fastForwardPitchKey);

  static Future<bool?> getCustomTitlebar() async =>
      await _prefs.getBool(_customTitleBarKey);

  static Future<bool?> getAutoCheckUpdates() async =>
      await _prefs.getBool(_autoCheckUpdatesKey);
  static Future<String?> getSkippedVersion() async =>
      await _prefs.getString(_skippedVersionKey);
}

class Defaults {
  static final defaultAudioDevice = AudioDevice.auto();
  static const showFForwardButton = true;
  static const fastForwardSpeed = 2.5;
  static const fastForwardPitch = 1.4;

  static const customTitleBar = true;

  static const autoCheckUpdates = true;
}
