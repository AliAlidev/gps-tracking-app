import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import '../services/location_service.dart';
import '../api/api_service.dart';
import '../database/database_helper.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final Battery _battery = Battery();
  final ApiService _apiService = ApiService.instance;

  bool _isTracking = false;
  int _batteryLevel = 100;
  Map<String, dynamic>? _stats;
  bool _isSyncing = false;

  bool get isTracking => _isTracking;
  int get batteryLevel => _batteryLevel;
  Map<String, dynamic>? get stats => _stats;
  bool get isSyncing => _isSyncing;

  LocationProvider() {
    _init();
  }

  Future<void> _init() async {
    await _updateBatteryLevel();
    await loadStats();
  }

  Future<void> _updateBatteryLevel() async {
    _batteryLevel = await _battery.batteryLevel;
    notifyListeners();
  }

  Future<void> startTracking({int? interval}) async {
    try {
      await _locationService.startTracking(interval: interval);
      _isTracking = true;
      await _updateBatteryLevel();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopTracking() async {
    await _locationService.stopTracking();
    _isTracking = false;
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _locationService.syncUnsyncedPoints();
      await loadStats();
    } catch (e) {
      // Handle error
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await _apiService.getGpsStats();
      notifyListeners();
    } catch (e) {
      // Load from local database as fallback
      await _loadLocalStats();
    }
  }

  Future<void> _loadLocalStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final points = await DatabaseHelper.instance.getGpsPoints(
      startDate: startOfDay,
    );

    int totalPoints = await DatabaseHelper.instance.getGpsPointsCount(
      startDate: startOfDay,
    );

    // Calculate distance
    double totalDistance = 0;
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      totalDistance += _calculateDistance(
        prev['latitude'] as double,
        prev['longitude'] as double,
        curr['latitude'] as double,
        curr['longitude'] as double,
      );
    }

    _stats = {
      'success': true,
      'stats': {
        'today': {
          'distance_km': totalDistance,
          'points_count': totalPoints,
        },
        'total_points': totalPoints,
      },
    };
    notifyListeners();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);
}
