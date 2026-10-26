import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/app_shell.dart';
import 'providers/ngo_provider.dart';
import 'providers/donation_provider.dart';
import 'providers/analytics_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NgoProvider()..fetch()),
        ChangeNotifierProvider(create: (_) => DonationProvider()..fetchPopulated()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()..fetch()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NGO Charity Flow Analytics',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF6F7FB),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}
