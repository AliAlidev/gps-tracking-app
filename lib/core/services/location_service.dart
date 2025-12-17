import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../api/api_service.dart';
import 'device_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  Timer? _syncTimer;
  bool _isTracking = false;
  int _trackingInterval = 10; // seconds
  Position? _lastPosition;
  DateTime? _lastPositionTime;

  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  bool get isTracking => _isTracking;

  Future<void> initialize() async {
    await _checkPermissions();
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> startTracking({int? interval}) async {
    if (_isTracking) return;

    bool hasPermission = await _checkPermissions();
    if (!hasPermission) {
      throw Exception('Location permissions not granted');
    }

    _trackingInterval = interval ?? _trackingInterval;
    _isTracking = true;

    // Configure location settings
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // Track every movement
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        await _handlePositionUpdate(position);
      },
      onError: (error) {
        print('Location error: $error');
      },
    );

    // Start periodic sync
    _startSyncTimer();
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    await _positionStream?.cancel();
    _positionStream = null;
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _handlePositionUpdate(Position position) async {
    // Check battery level
    int batteryLevel = await _battery.batteryLevel;
    if (batteryLevel < 15) {
      await stopTracking();
      return;
    }

    // Adaptive interval based on movement
    if (_lastPosition != null) {
      double distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // If stationary (less than 10 meters), reduce frequency
      if (distance < 10 && _lastPositionTime != null) {
        Duration timeSinceLastPosition = DateTime.now().difference(_lastPositionTime!);
        if (timeSinceLastPosition.inSeconds < _trackingInterval * 2) {
          return; // Skip this update
        }
      }
    }

    _lastPosition = position;
    _lastPositionTime = DateTime.now();

    // Get network type
    ConnectivityResult connectivityResult = await _connectivity.checkConnectivity();
    String networkType = connectivityResult.toString().split('.').last;

    // Get device info
    final deviceService = DeviceService();
    String? deviceId = deviceService.deviceId;

    if (deviceId == null) {
      await deviceService.initialize();
      deviceId = deviceService.deviceId;
    }

    // Store GPS point locally
    await DatabaseHelper.instance.insertGpsPoint({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'battery_level': batteryLevel,
      'network_type': networkType,
      'device_id': deviceId,
      'is_synced': 0, // 0 = false, 1 = true
    });
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await syncUnsyncedPoints();
    });
  }

  Future<void> trackLocationInBackground() async {
    try {
      Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (position != null) {
        await _handlePositionUpdate(position);
      }
    } catch (e) {
      print('Background tracking error: $e');
    }
  }

  Future<void> syncUnsyncedPoints() async {
    try {
      List<Map<String, dynamic>> unsyncedPoints = 
          await DatabaseHelper.instance.getUnsyncedGpsPoints();

      if (unsyncedPoints.isEmpty) return;

      // Check connectivity
      ConnectivityResult connectivityResult = 
          await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        return; // No internet connection
      }

      // Prepare points for API
      List<Map<String, dynamic>> points = unsyncedPoints.map((point) {
        return {
          'latitude': point['latitude'],
          'longitude': point['longitude'],
          'accuracy': point['accuracy'],
          'timestamp': point['timestamp'],
          'battery_level': point['battery_level'],
          'network_type': point['network_type'],
        };
      }).toList();

      // Send to server
      bool success = await ApiService.instance.syncGpsPoints(points);

      if (success) {
        // Mark as synced
        for (var point in unsyncedPoints) {
          await DatabaseHelper.instance.markGpsPointAsSynced(point['id']);
        }
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> setTrackingInterval(int seconds) async {
    _trackingInterval = seconds.clamp(5, 60);
    if (_isTracking) {
      await stopTracking();
      await startTracking(interval: _trackingInterval);
    }
  }

  int getTrackingInterval() => _trackingInterval;
}

