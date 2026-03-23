import 'package:flutter/material.dart';
import '../client/notifications/notifications_screen.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const NotificationsScreen(),
    );
  }
}
