import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wio_pharmacy/view/splash_screen.dart';
import 'package:wio_pharmacy/viewmodel/alert/alert_view_model.dart';
import 'package:wio_pharmacy/viewmodel/analytics/analytics_view_model.dart';
import 'package:wio_pharmacy/viewmodel/authentication/authentication_view_model.dart';
import 'package:wio_pharmacy/viewmodel/dashboard/dashboard_view_model.dart';
import 'package:wio_pharmacy/viewmodel/inventory/inventory_view_model.dart';
import 'package:wio_pharmacy/viewmodel/navigation_view_model.dart';
import 'package:wio_pharmacy/viewmodel/profile/profile_view_model.dart';
import 'package:wio_pharmacy/viewmodel/sales/sales_view_model.dart';
import 'package:wio_pharmacy/viewmodel/settings/settings_view_model.dart';
import 'package:wio_pharmacy/viewmodel/suppliers/suppliers_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final googleMapsApiKey = "AIzaSyBK5-pwhZyjEIPVHx5fr0TTSrlHYJe5FZ8";

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationViewModel()),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => InventoryViewModel()),
        ChangeNotifierProvider(create: (_) => AlertViewModel()),
        ChangeNotifierProvider(create: (_) => AnalyticsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SalesViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => SuppliersViewModel()),

        // Provide a default uid or handle it appropriately
        Provider<String>(create: (_) => googleMapsApiKey),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Wio Pharmacy',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
