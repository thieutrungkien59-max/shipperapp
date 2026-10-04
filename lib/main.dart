import 'package:flutter/material.dart';

// Import màn hình đăng nhập thay vì HomeScreen
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSession = await SessionService.hasSession();
  runApp(MyApp(hasSession: hasSession));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.hasSession}) : super(key: key);

  final bool hasSession;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogiRoute Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: hasSession ? const HomeScreen() : const LoginScreen(),
    );
  }
}
