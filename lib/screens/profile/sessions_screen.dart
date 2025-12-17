import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/api/api_service.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.instance.getActiveSessions();
      if (response['success'] == true) {
        setState(() {
          _sessions = List<Map<String, dynamic>>.from(response['devices'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sessions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logoutAllDevices() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout All Devices'),
        content: const Text('Are you sure you want to logout from all devices?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logoutAllDevices();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out from all devices'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logoutAllDevices,
            tooltip: 'Logout All Devices',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('No active sessions'))
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.phone_android),
                          title: Text(session['device_name'] ?? 'Unknown Device'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (session['device_model'] != null)
                                Text('Model: ${session['device_model']}'),
                              if (session['last_active_at'] != null)
                                Text(
                                  'Last active: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(session['last_active_at']))}',
                                ),
                              if (session['login_at'] != null)
                                Text(
                                  'Login: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(session['login_at']))}',
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
