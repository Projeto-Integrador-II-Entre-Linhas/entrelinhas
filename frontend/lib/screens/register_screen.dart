import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

const Color kFundo = Color(0xFFDCCEE6);
const Color kCard = Color(0xFFEDE3F4);
const Color kBotaoPrincipal = Color(0xFF6E4A8E);
const Color kBotaoSecundario = Color(0xFF8A68B1);
const Color kTitulo = Color(0xFF4F2A75);
const Color kIcones = Color(0xFF6E4A8E);

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
    setState(() => loading = true);

    final auth = AuthService();

    try {
      final data = await auth.register(
        _nome.text.trim(),
        _usuario.text.trim(),
        _email.text.trim(),
        _senha.text.trim(),
      );

      if (!mounted) return;

      if (data['success'] == true || data['user'] != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sucesso'),
            content: const Text('Conta criada!'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Ok'),
              )
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Erro'),
            content: Text(data.toString()),
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

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kIcones),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .6),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: kIcones.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: kIcones, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFundo,
      appBar: AppBar(
        backgroundColor: kFundo,
        elevation: 0,
        iconTheme: const IconThemeData(color: kIcones),
        title: const Text(
          'Criar Conta',
          style: TextStyle(color: kTitulo, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(controller: _nome, decoration: _input('Nome', Icons.person)),
                  const SizedBox(height: 12),
                  TextField(controller: _usuario, decoration: _input('Usuário', Icons.account_circle)),
                  const SizedBox(height: 12),
                  TextField(controller: _email, decoration: _input('Email', Icons.email)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _senha,
                    decoration: _input('Senha', Icons.lock),
                    obscureText: true,
                  ),
                  const SizedBox(height: 25),

                  loading
                      ? const CircularProgressIndicator(color: kBotaoPrincipal)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBotaoPrincipal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _register,
                            child: const Text(
                              'Cadastrar',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
