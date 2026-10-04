import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';

class ApiStatusScreen extends StatefulWidget {
  const ApiStatusScreen({super.key});

  @override
  State<ApiStatusScreen> createState() => _ApiStatusScreenState();
}

class _ApiStatusScreenState extends State<ApiStatusScreen> {
  bool _isLoading = true;
  final Map<String, String> _results = <String, String>{};

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() => _isLoading = true);
    final api = ApiServices(timeout: const Duration(seconds: 8));
    final prefs = await SharedPreferences.getInstance();
    final accountId = prefs.getString('maTk');
    final driverId = prefs.getString('maSp');
    final token = await SessionService.getAccessToken();

    final checks = <String, Future<dynamic> Function()>{
      'Identity': () => api.get('/api/identity/me'),
      'Current User': () => api.get('/api/identity/me'),
      'Order': () => api.get('/api/order?customerId=$accountId'),
      'Delivery': () => api.get('/api/delivery/health'),
      'Finance': () => api.get('/api/finance/wallet/$driverId'),
    };

    final next = <String, String>{
      'Session': token?.isNotEmpty == true
          ? 'PASS - JWT đã lưu'
          : 'COMPAT - chưa có JWT',
      'GPS': 'DEVICE - kiểm tra khi bật Online',
      'Quote': 'ACTION - kiểm tra khi bấm Chỉ đường',
      'Assignment': 'ACTION - kiểm tra khi nhận đơn',
    };

    for (final entry in checks.entries) {
      try {
        await entry.value();
        next[entry.key] = 'PASS';
      } on ApiException catch (error) {
        next[entry.key] = 'FAIL ${error.statusCode ?? ''}'.trim();
      } catch (_) {
        next[entry.key] = 'FAIL';
      }
    }

    if (!mounted) return;
    setState(() {
      _results
        ..clear()
        ..addAll(next);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API STATUS')),
      body: RefreshIndicator(
        onRefresh: _runChecks,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API MODE: ${AppConfig.apiModeLabel}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(AppConfig.apiBaseUrl),
                    if (AppConfig.demoMode) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'DEMO MODE đang bật. Dữ liệu mô phỏng phải được gắn nhãn rõ.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (final entry in _results.entries)
                ListTile(
                  leading: Icon(
                    entry.value.startsWith('PASS')
                        ? Icons.check_circle
                        : entry.value.startsWith('FAIL')
                        ? Icons.cancel
                        : Icons.info,
                    color: entry.value.startsWith('PASS')
                        ? Colors.green
                        : entry.value.startsWith('FAIL')
                        ? Colors.red
                        : Colors.orange,
                  ),
                  title: Text(entry.key),
                  trailing: Text(entry.value),
                ),
          ],
        ),
      ),
    );
  }
}
