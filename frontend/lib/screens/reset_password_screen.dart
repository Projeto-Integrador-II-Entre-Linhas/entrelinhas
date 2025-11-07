import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  bool loading = false;

  Future<void> _resetPassword() async {
    final novaSenha = _passwordController.text.trim();

    if (novaSenha.isEmpty) {
      _show('Preencha a nova senha.');
      return;
    }

    setState(() => loading = true);
    try {
      final api = ApiService();
      final res = await api.post('auth/reset-password', {
        'token': widget.token, // token vem do deep link
        'novaSenha': novaSenha,
      });

      if (res.statusCode == 200) {
        _show('Senha redefinida com sucesso!');
        Navigator.pop(context);
      } else {
        _show('Erro: ${res.body}');
      }
    } catch (e) {
      _show('Erro: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir Senha')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Token: ${widget.token}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _resetPassword,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Redefinir Senha'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
