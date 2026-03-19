import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'presentation/screens/client/map_screen/map_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/store_provider.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/grocer_catalog_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/order_provider.dart';
import 'data/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  
  // Initialize Firebase (fails gracefully if config is missing)
  try {
    await Firebase.initializeApp();
    await FCMService().initialize();
  } catch (e) {
    debugPrint("Firebase init log: $e");
  }

  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => GrocerCatalogProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'MyHanut',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          MapScreen.routeName: (context) => const MapScreen(),
        },
      ),
    );
  }
}
