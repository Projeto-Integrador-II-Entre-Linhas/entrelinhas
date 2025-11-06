import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/auth_provider.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // abrir box simples para fichamentos offline (RNF06)
  await Hive.openBox('fichamentos_offline');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..tryAutoLogin(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'EntreLinhas',
            theme: AppTheme.lightTheme,
            home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
            routes: {
              '/home': (_) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
