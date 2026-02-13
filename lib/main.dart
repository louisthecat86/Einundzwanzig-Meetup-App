import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/intro.dart';
import 'screens/dashboard.dart';
import 'theme.dart';
import 'models/user.dart';
import 'services/nostr_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Bestehenden User laden
  final user = await UserProfile.load();

  runApp(MyApp(startScreen: user == null ? const IntroScreen() : const DashboardScreen()));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Einundzwanzig Meetup',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: startScreen,
    );
  }
}