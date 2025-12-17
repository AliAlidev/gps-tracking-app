import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/device_utils.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  String? _deviceId;
  String? _deviceName;
  String? _deviceModel;
  String? _osVersion;

  Future<void> initialize() async {
    _deviceId = await DeviceUtils.getDeviceId();
    _deviceName = await DeviceUtils.getDeviceName();
    _deviceModel = await DeviceUtils.getDeviceModel();
    _osVersion = await DeviceUtils.getOsVersion();
  }

  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  String? get deviceModel => _deviceModel;
  String? get osVersion => _osVersion;

  Future<void> updateDeviceName(String name) async {
    await DeviceUtils.setDeviceName(name);
    _deviceName = name;
  }

  Map<String, dynamic> getDeviceInfo() {
    return {
      'device_id': _deviceId,
      'device_name': _deviceName ?? 'Unknown Device',
      'device_model': _deviceModel,
      'os_version': _osVersion,
      'app_version': '1.0.0',
      'installation_timestamp': DateTime.now().toIso8601String(),
    };
  }
}

