import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  String _status = 'En attente...';

  Future<void> _checkApi() async {
    try {
      final result = await _api.get(ApiConstants.health);
      setState(() => _status = '✅ API connectée: ${result['status']}');
    } catch (e) {
      setState(() => _status = '❌ Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My App'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_android, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _checkApi,
              icon: const Icon(Icons.cloud),
              label: const Text('Tester la connexion API'),
            ),
          ],
        ),
      ),
    );
  }
}
