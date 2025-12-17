import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const String _deviceIdKey = 'device_unique_id';
  static const String _deviceNameKey = 'device_name';
  static const Uuid _uuid = Uuid();

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = await _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  static Future<String> _generateDeviceId() async {
    try {
      String deviceModel = '';
      String osVersion = '';
      String installationTimestamp = DateTime.now().millisecondsSinceEpoch.toString();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
        osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceModel = iosInfo.model;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }

      // Combine all components
      String combined = '$deviceModel|$osVersion|$installationTimestamp';
      
      // Generate UUID based on combined string
      return _uuid.v5(Uuid.NAMESPACE_URL, combined);
    } catch (e) {
      // Fallback to random UUID
      return _uuid.v4();
    }
  }

  static Future<String> getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.model;
      }
    } catch (e) {
      // ignore
    }
    return 'Unknown Device';
  }

  static Future<String> getOsVersion() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      // ignore
    }
    return 'Unknown OS';
  }

  static Future<String?> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceNameKey);
  }

  static Future<void> setDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceNameKey, name);
  }
}

