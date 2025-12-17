import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/location_service.dart';
import '../../core/database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _trackingInterval = 10;
  bool _wifiOnly = false;
  bool _batterySaver = false;
  bool _notificationsEnabled = true;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _trackingInterval = prefs.getInt('tracking_interval') ?? 10;
      _wifiOnly = prefs.getBool('wifi_only') ?? false;
      _batterySaver = prefs.getBool('battery_saver') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _language = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _saveTrackingInterval(int value) async {
    setState(() {
      _trackingInterval = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tracking_interval', value);
    await LocationService().setTrackingInterval(value);
  }

  Future<void> _saveWifiOnly(bool value) async {
    setState(() {
      _wifiOnly = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifi_only', value);
  }

  Future<void> _saveBatterySaver(bool value) async {
    setState(() {
      _batterySaver = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_saver', value);
  }

  Future<void> _saveNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _saveLanguage(String value) async {
    setState(() {
      _language = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GPS Tracking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Tracking Interval: $_trackingInterval seconds'),
                  Slider(
                    value: _trackingInterval.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '$_trackingInterval seconds',
                    onChanged: (value) {
                      _saveTrackingInterval(value.toInt());
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('WiFi Only Sync'),
                  subtitle: const Text('Only sync when connected to WiFi'),
                  value: _wifiOnly,
                  onChanged: _saveWifiOnly,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Battery Saver Mode'),
                  subtitle: const Text('Reduce tracking frequency to save battery'),
                  value: _batterySaver,
                  onChanged: _saveBatterySaver,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable push notifications'),
                  value: _notificationsEnabled,
                  onChanged: _saveNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Language'),
                  trailing: DropdownButton<String>(
                    value: _language,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _saveLanguage(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
