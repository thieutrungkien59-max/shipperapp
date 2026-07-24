import 'package:flutter/material.dart';
// Import màn hình đăng nhập thay vì HomeScreen
import 'features/auth/screens/login_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipper App',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      // Đặt màn hình khởi chạy là LoginScreen
      home: const LoginScreen(), 
    );
  }
}