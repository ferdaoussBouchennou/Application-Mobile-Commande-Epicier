import 'package:flutter/material.dart';
import '../setup/grocer_setup_screen.dart';

class GrocerProfileScreen extends StatelessWidget {
  const GrocerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GrocerSetupScreen(
      isEditing: true,
      submitEndpoint: '/epicier/profile',
      finalButtonText: 'Enregistrer',
    );
  }
}

