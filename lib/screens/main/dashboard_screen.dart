import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Text('Welcome, ${authProvider.user?.name ?? 'User'}');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<LocationProvider>(context, listen: false).loadStats();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<LocationProvider>(context, listen: false).loadStats();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<LocationProvider>(
                builder: (context, locationProvider, child) {
                  final stats = locationProvider.stats?['stats'];
                  final today = stats?['today'] ?? {};
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Distance Today',
                              value: '${(today['distance_km'] ?? 0.0).toStringAsFixed(2)} km',
                              icon: Icons.straighten,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'GPS Points',
                              value: '${today['points_count'] ?? 0}',
                              icon: Icons.location_on,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Battery',
                              value: '${locationProvider.batteryLevel}%',
                              icon: Icons.battery_charging_full,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Status',
                              value: locationProvider.isTracking ? 'Active' : 'Inactive',
                              icon: locationProvider.isTracking
                                  ? Icons.play_circle_filled
                                  : Icons.pause_circle_filled,
                              color: locationProvider.isTracking
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildTrackingControls(),
              const SizedBox(height: 24),
              _buildWeeklyChart(),
              const SizedBox(height: 24),
              _buildLastSyncInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingControls() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tracking Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: locationProvider.isSyncing
                            ? null
                            : () {
                                if (locationProvider.isTracking) {
                                  locationProvider.stopTracking();
                                } else {
                                  locationProvider.startTracking();
                                }
                              },
                        icon: Icon(
                          locationProvider.isTracking
                              ? Icons.stop
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          locationProvider.isTracking
                              ? 'Stop Tracking'
                              : 'Start Tracking',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: locationProvider.isTracking
                              ? Colors.red
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: locationProvider.isSyncing
                            ? null
                            : () {
                                locationProvider.syncNow();
                              },
                        icon: locationProvider.isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: const Text('Sync Now'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final weeklyData = locationProvider.stats?['stats']?['weekly_data'] ?? [];
        
        if (weeklyData.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('No weekly data available'),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Weekly Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (weeklyData.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < weeklyData.length) {
                                final date = weeklyData[value.toInt()]['date'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MMM dd').format(DateTime.parse(date)),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: weeklyData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: (data['count'] as int).toDouble(),
                              color: Colors.blue,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLastSyncInfo() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final lastSync = locationProvider.stats?['stats']?['last_sync'];
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Sync',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        lastSync != null
                            ? DateFormat('MMM dd, yyyy HH:mm').format(
                                DateTime.parse(lastSync),
                              )
                            : 'Never',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
