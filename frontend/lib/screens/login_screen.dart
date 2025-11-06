import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool loading = false;

  void _login() async {
    setState(() => loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.login(_email.text.trim(), _senha.text.trim());
    setState(() => loading = false);
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Erro'), content: const Text('Credenciais inválidas'), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Ok'))]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                const SizedBox(height: 8),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'E-mail')),
                const SizedBox(height: 12),
                TextField(controller: _senha, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
                const SizedBox(height: 20),
                loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _login, child: const SizedBox(width: double.infinity, child: Center(child: Text('Entrar')))),
                const SizedBox(height: 8),
                TextButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Criar conta')),
                TextButton(onPressed: ()=> showDialog(context: context, builder: (_) => const _ForgotDialog()), child: const Text('Esqueci minha senha')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotDialog extends StatefulWidget {
  const _ForgotDialog();
  @override
  State<_ForgotDialog> createState() => _ForgotDialogState();
}

class _ForgotDialogState extends State<_ForgotDialog> {
  final _email = TextEditingController();
  bool loading = false;
  void _send() async {
    setState(()=>loading=true);
    try {
      // requisição
      final ApiService api = ApiService();
      final res = await api.post('auth/forgot-password', {'email': _email.text.trim()});
      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link de redefinição enviado')));
      } else {
        final body = res.body;
        showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Erro'), content: Text(body), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Ok'))]));
      }
    } catch (e) {
      showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Erro'), content: Text(e.toString()), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Ok'))]));
    } finally { setState(()=>loading=false); }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar senha'),
      content: TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancelar')),
        loading ? const CircularProgressIndicator() : TextButton(onPressed: _send, child: const Text('Enviar'))
      ],
    );
  }
}
