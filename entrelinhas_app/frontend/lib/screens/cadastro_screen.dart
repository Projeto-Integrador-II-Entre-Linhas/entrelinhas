import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CadastroScreen extends StatefulWidget {
  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final AuthService auth = AuthService();
  bool loading = false;

  void register() async {
    setState(() => loading = true);
    bool success = await auth.register(_nomeController.text, _usuarioController.text, _emailController.text, _senhaController.text);
    setState(() => loading = false);

    if(success) Navigator.pop(context);
    else showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text('Erro'), content: Text('Cadastro falhou'), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text('Ok'))]),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nomeController, decoration: InputDecoration(labelText:'Nome')),
            TextField(controller: _usuarioController, decoration: InputDecoration(labelText:'Usuário')),
            TextField(controller: _emailController, decoration: InputDecoration(labelText:'Email')),
            TextField(controller: _senhaController, decoration: InputDecoration(labelText:'Senha'), obscureText:true),
            SizedBox(height:16),
            loading ? CircularProgressIndicator() : ElevatedButton(onPressed: register, child: Text('Cadastrar')),
          ],
        ),
      ),
    );
  }
}
