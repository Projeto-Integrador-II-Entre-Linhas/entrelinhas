import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final AuthService auth = AuthService();
  bool loading = false;

  void login() async {
    setState(() => loading = true);
    bool success = await auth.login(_emailController.text, _senhaController.text);
    setState(() => loading = false);

    if(success) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    else showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text('Erro'), content: Text('Login falhou'), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text('Ok'))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText:'Email')),
            TextField(controller: _senhaController, decoration: InputDecoration(labelText:'Senha'), obscureText:true),
            SizedBox(height: 16),
            loading ? CircularProgressIndicator() : ElevatedButton(onPressed: login, child: Text('Login')),
            TextButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroScreen())), child: Text('Criar Conta')),
            TextButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_) => RecuperarSenhaScreen())), child: Text('Esqueci minha senha')),
          ],
        ),
      ),
    );
  }
}
