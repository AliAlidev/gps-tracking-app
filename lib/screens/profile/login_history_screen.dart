import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_service.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _history = [];
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _history = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.instance.getLoginHistory(page: _currentPage);
      if (response['success'] == true) {
        final data = response['history']?['data'] ?? [];
        setState(() {
          _history.addAll(List<Map<String, dynamic>>.from(data));
          _hasMore = response['history']?['next_page_url'] != null;
          _currentPage++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return 'green';
      case 'logged_out':
        return 'grey';
      case 'forced_logout':
        return 'red';
      default:
        return 'grey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadHistory(refresh: true),
          ),
        ],
      ),
      body: _history.isEmpty && !_isLoading
          ? const Center(child: Text('No login history'))
          : RefreshIndicator(
              onRefresh: () => _loadHistory(refresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _history.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _history.length) {
                    if (_isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    _loadHistory();
                    return const SizedBox.shrink();
                  }

                  final entry = _history[index];
                  final status = entry['status'] as String?;
                  final statusColor = _getStatusColor(status);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        status == 'active'
                            ? Icons.check_circle
                            : status == 'forced_logout'
                                ? Icons.cancel
                                : Icons.logout,
                        color: statusColor == 'green'
                            ? Colors.green
                            : statusColor == 'red'
                                ? Colors.red
                                : Colors.grey,
                      ),
                      title: Text(entry['device_name'] ?? 'Unknown Device'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry['ip_address'] != null)
                            Text('IP: ${entry['ip_address']}'),
                          if (entry['login_at'] != null)
                            Text(
                              'Login: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(entry['login_at']))}',
                            ),
                          if (entry['logout_at'] != null)
                            Text(
                              'Logout: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(entry['logout_at']))}',
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor == 'green'
                              ? Colors.green
                              : statusColor == 'red'
                                  ? Colors.red
                                  : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (status ?? 'unknown').toUpperCase().replaceAll('_', ' '),
                          style: const TextStyle(
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

