import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nome = TextEditingController();
  final _usuario = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool loading = false;

  void _register() async {
    setState(()=>loading=true);
    final auth = AuthService();
    try {
      final data = await auth.register(_nome.text.trim(), _usuario.text.trim(), _email.text.trim(), _senha.text.trim());
      if (data['success'] == true || data['user'] != null) {
        showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Sucesso'), content: const Text('Conta criada!'), actions: [TextButton(onPressed: ()=>Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Ok'))]));
      } else {
        showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Erro'), content: Text(data.toString()), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Ok'))]));
      }
    } catch (e) {
      showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Erro'), content: Text(e.toString()), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Ok'))]));
    } finally { setState(()=>loading=false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 8),
              TextField(controller: _usuario, decoration: const InputDecoration(labelText: 'Usuário')),
              const SizedBox(height: 8),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: _senha, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
              const SizedBox(height: 20),
              loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _register, child: const SizedBox(width: double.infinity, child: Center(child: Text('Cadastrar'))))
            ],
          ),
        ),
      ),
    );
  }
}
