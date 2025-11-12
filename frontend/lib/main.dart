import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_links/app_links.dart';
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
  late final AppLinks _appLinks;
  String? _deepLinkToken;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleUri(initialUri);

      _appLinks.uriLinkStream.listen((uri) {
        _handleUri(uri);
      });
    } catch (e) {
      debugPrint('Erro ao processar deep link: $e');
    }
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'entrelinhas' && uri.host == 'reset-password') {
      final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (token.isNotEmpty) {
        setState(() => _deepLinkToken = token);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..tryAutoLogin(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'EntreLinhas',
            theme: AppTheme.lightTheme,
            home: _deepLinkToken != null
                ? ResetPasswordScreen(token: _deepLinkToken!)
                : auth.isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen(),
            routes: {
              '/home': (_) => const HomeScreen(),
              '/login': (_) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}
