import 'package:workmanager/workmanager.dart';
import 'location_service.dart';

class BackgroundService {
  static const String taskName = "gpsTrackingTask";
  static const String periodicTaskName = "gpsTrackingPeriodicTask";

  static Future<void> initialize() async {
    await Workmanager().registerPeriodicTask(
      periodicTaskName,
      taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(periodicTaskName);
  }
}

