import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../services/api_service.dart';
import 'dart:convert';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool loading = false;

  final background = const Color(0xFFDCCEE6);
  final card = const Color(0xFFEDE3F4);
  final primaryButton = const Color(0xFF6E4A8E);
  final secondaryButton = const Color(0xFF8A68B1);
  final titleText = const Color(0xFF4F2A75);
  final iconColor = const Color(0xFF6E4A8E);

  void _login() async {
    setState(() => loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final ok = await auth.login(_email.text.trim(), _senha.text.trim());
      if (!mounted) return;

      setState(() => loading = false);

      if (ok) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      String msg = "Erro ao fazer login";

      if (e.toString().contains("{")) {
        try {
          final map = jsonDecode(e.toString().split(": ").last);
          msg = map['error'] ?? msg;
        } catch (_) {}
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                Icon(Icons.menu_book_rounded, size: 90, color: iconColor),
                const SizedBox(height: 10),

                Text(
                  "Entre Linhas",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: titleText,
                  ),
                ),

                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          labelStyle: TextStyle(color: titleText),
                          prefixIcon: Icon(Icons.email_rounded, color: iconColor),
                          filled: true,
                          fillColor: background.withValues(alpha: .6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _senha,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          labelStyle: TextStyle(color: titleText),
                          prefixIcon: Icon(Icons.lock_rounded, color: iconColor),
                          filled: true,
                          fillColor: background.withValues(alpha: .6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        obscureText: true,
                      ),

                      const SizedBox(height: 22),

                      loading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryButton,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _login,
                                child: const Text(
                                  'Entrar',
                                  style: TextStyle(
                                      color: Color(0xFFEDE3F4), fontSize: 16),
                                ),
                              ),
                            ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: Text(
                          'Criar conta',
                          style: TextStyle(
                            color: secondaryButton,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const _ForgotDialog(),
                        ),
                        child: Text(
                          'Esqueci minha senha',
                          style: TextStyle(
                            color: secondaryButton,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//Forgot Dialog

class _ForgotDialog extends StatefulWidget {
  const _ForgotDialog();

  @override
  State<_ForgotDialog> createState() => _ForgotDialogState();
}

class _ForgotDialogState extends State<_ForgotDialog> {
  final _email = TextEditingController();
  bool loading = false;

  final primaryButton = const Color(0xFF6E4A8E);
  final titleText = const Color(0xFF4F2A75);
  final iconColor = const Color(0xFF6E4A8E);

  void _send() async {
    setState(() => loading = true);

    try {
      final api = ApiService();
      final res = await api.post(
        'auth/forgot-password',
        {'email': _email.text.trim()},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link de redefinição enviado')),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Erro'),
            content: Text(res.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ok'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            )
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFEDE3F4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Recuperar senha',
        style: TextStyle(color: titleText, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _email,
        decoration: InputDecoration(
          labelText: 'E-mail',
          labelStyle: TextStyle(color: titleText),
          prefixIcon: Icon(Icons.email_rounded, color: iconColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: primaryButton),
          ),
        ),
        loading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: _send,
                child: Text(
                  'Enviar',
                  style: TextStyle(color: primaryButton),
                ),
              ),
      ],
    );
  }
}
