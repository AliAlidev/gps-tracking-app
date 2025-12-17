import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/device_utils.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;
  ApiService._internal();

  late Dio _dio;
  String? _baseUrl;
  String? _token;

  static const String _tokenKey = 'auth_token';
  static const String _baseUrlKey = 'api_base_url';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to localhost, but can be changed via SharedPreferences
    // For Android emulator, use http://10.0.2.2:8000/api
    // For iOS simulator, use http://localhost:8000/api
    // For physical device, use your computer's IP address
    _baseUrl = prefs.getString(_baseUrlKey) ?? 'http://10.0.2.2:8000/api';
    _token = prefs.getString(_tokenKey);

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl!,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add device ID to headers
        String deviceId = await DeviceUtils.getDeviceId();
        options.headers['X-Device-ID'] = deviceId;

        // Add auth token if available
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }

        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          _token = null;
          SharedPreferences.getInstance().then((prefs) {
            prefs.remove(_tokenKey);
          });
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    _dio.options.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        ...deviceInfo,
      });

      if (response.data['success'] == true) {
        await setToken(response.data['token']);
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Login failed');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      rethrow;
    }
  }

  Future<void> logout({String? deviceId}) async {
    try {
      await _dio.post('/auth/logout', data: {'device_id': deviceId});
      await clearToken();
    } catch (e) {
      // Ignore errors on logout
    }
  }

  Future<void> logoutAllDevices() async {
    try {
      await _dio.post('/auth/logout-all');
      await clearToken();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<Map<String, dynamic>> getActiveSessions() async {
    final response = await _dio.get('/auth/sessions');
    return response.data;
  }

  Future<Map<String, dynamic>> getLoginHistory({int page = 1}) async {
    final response = await _dio.get('/auth/login-history', queryParameters: {'page': page});
    return response.data;
  }

  // GPS endpoints
  Future<bool> syncGpsPoints(List<Map<String, dynamic>> points) async {
    try {
      final response = await _dio.post('/gps/store', data: {'points': points});
      return response.data['success'] == true;
    } catch (e) {
      print('Sync GPS points error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getGpsStats() async {
    final response = await _dio.get('/gps/stats');
    return response.data;
  }

  Future<Map<String, dynamic>> getGpsPoints({int page = 1}) async {
    final response = await _dio.get('/gps/points', queryParameters: {'page': page});
    return response.data;
  }

  // Advertisement endpoints
  Future<Map<String, dynamic>> getAdvertisements({String? search}) async {
    final response = await _dio.get('/advertisements', queryParameters: {
      if (search != null) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getAdvertisement(int id) async {
    final response = await _dio.get('/advertisements/$id');
    return response.data;
  }

  // Agent endpoints
  Future<Map<String, dynamic>> registerAgent({
    required int advertisementId,
    required String name,
    String? email,
    String? phone,
  }) async {
    final response = await _dio.post('/agents', data: {
      'advertisement_id': advertisementId,
      'name': name,
      'email': email,
      'phone': phone,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getAgents(int advertisementId) async {
    final response = await _dio.get('/agents', queryParameters: {
      'advertisement_id': advertisementId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateAgent(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/agents/$id', data: data);
    return response.data;
  }

  Future<void> deleteAgent(int id) async {
    await _dio.delete('/agents/$id');
  }
}

