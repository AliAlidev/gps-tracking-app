import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'core/services/device_service.dart';
import 'core/services/location_service.dart';
import 'core/services/background_service.dart';
import 'core/api/api_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/advertisement_provider.dart';
import 'core/database/database_helper.dart';
import 'core/utils/device_utils.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/splash_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Hive.initFlutter();
      final locationService = LocationService();
      await locationService.initialize();
      await locationService.trackLocationInBackground();
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize API Service
  await ApiService.instance.initialize();
  
  // Initialize database
  await DatabaseHelper.instance.database;
  
  // Initialize WorkManager for background tasks
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => AdvertisementProvider()),
      ],
      child: MaterialApp(
        title: 'GPS Tracking App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

