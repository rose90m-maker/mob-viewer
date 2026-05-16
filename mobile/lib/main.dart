import 'package:flutter/material.dart';
import 'config.dart';
import 'api_client.dart';

void main() {
  runApp(const MobViewerApp());
}

class MobViewerApp extends StatelessWidget {
  const MobViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mob-viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HealthPage(),
    );
  }
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final ApiClient _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  String _status = 'checking...';

  @override
  void initState() {
    super.initState();
    _ping();
  }

  Future<void> _ping() async {
    try {
      final result = await _api.health();
      setState(() => _status = 'OK: ${result['service']}');
    } catch (e) {
      setState(() => _status = 'error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('mob-viewer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Backend: ${ApiConfig.baseUrl}'),
            const SizedBox(height: 16),
            Text('Status: $_status'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _ping, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
