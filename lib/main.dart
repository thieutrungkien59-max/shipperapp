import 'package:flutter/material.dart';
// Đường dẫn import chính xác dựa trên cấu trúc file của dự án
import 'features/home/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipper App',
      // Tắt dải băng 'DEBUG' màu đỏ ở góc trên cùng bên phải
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      // Gọi màn hình HomeScreen hiển thị đầu tiên
      home: const HomeScreen(), 
    );
  }
}