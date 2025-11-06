import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'screens/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entre Linhas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), // <- sem const e usando a classe correta
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => LoginScreen(),
      },
    );
  }
}
