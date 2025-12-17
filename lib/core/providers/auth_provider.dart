import 'package:flutter/foundation.dart';
import '../api/api_service.dart';
import '../services/device_service.dart';
import '../../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final DeviceService _deviceService = DeviceService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _deviceService.initialize();
      final deviceInfo = _deviceService.getDeviceInfo();

      final response = await _apiService.login(
        email: email,
        password: password,
        deviceInfo: deviceInfo,
      );

      if (response['success'] == true) {
        _user = UserModel.fromJson(response['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout(deviceId: _deviceService.deviceId);
      _user = null;
      notifyListeners();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> logoutAllDevices() async {
    try {
      await _apiService.logoutAllDevices();
      _user = null;
      notifyListeners();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> checkAuth() async {
    try {
      final response = await _apiService.getMe();
      if (response['success'] == true) {
        _user = UserModel.fromJson(response['user']);
        notifyListeners();
      }
    } catch (e) {
      _user = null;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

