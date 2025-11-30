import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/auth_provider.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('fichamentos_offline');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..tryAutoLogin(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'EntreLinhas',
            theme: AppTheme.lightTheme,

            // rota do navegador
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '');

              // rota web: http://localhost:57716/#/reset-password/TOKEN
              if (uri.pathSegments.isNotEmpty &&
                  uri.pathSegments.first == 'reset-password') {
                
                final token = uri.pathSegments.length > 1 ? uri.pathSegments[1] : '';

                return MaterialPageRoute(
                  builder: (_) => ResetPasswordScreen(token: token),
                );
              }

              // Rotas normais
              if (settings.name == '/home') {
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              }
              if (settings.name == '/login') {
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              }

              return null; 
            },

            home: auth.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}