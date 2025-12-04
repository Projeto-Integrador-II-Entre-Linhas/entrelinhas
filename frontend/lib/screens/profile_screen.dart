import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../config.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nome = TextEditingController();
  final _usuario = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _generos = TextEditingController();

  File? _avatar;
  String? avatarUrl;
  bool loading = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() => loading = true);
    try {
      final r = await ApiService().get('users/me');
      if (r.statusCode == 200 && r.body.isNotEmpty) {
        final map = jsonDecode(r.body);
        _nome.text = map['nome'] ?? '';
        _usuario.text = map['usuario'] ?? '';
        _email.text = map['email'] ?? '';
        _generos.text = (map['generos_preferidos'] as List?)?.join(', ') ?? '';
        avatarUrl = map['avatar'];
      }
    } catch (e) {
      _show('Erro ao carregar perfil: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;

    final f = File(x.path);
    final size = await f.length();
    if (size > 2 * 1024 * 1024) {
      _show('Arquivo acima de 2MB');
      return;
    }

    setState(() => _avatar = f);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final fields = <String, String>{
        if (_nome.text.trim().isNotEmpty) 'nome': _nome.text.trim(),
        if (_usuario.text.trim().isNotEmpty) 'usuario': _usuario.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_senha.text.trim().isNotEmpty) 'senha': _senha.text.trim(),
        if (_generos.text.trim().isNotEmpty)
          'generos_preferidos': _generos.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .join(','),
      };

      final resp = await ApiService().putMultipart(
        'users/me',
        fields,
        file: _avatar,
        fileField: 'avatar',
      );

      if (resp.statusCode == 200) {
        _show('Perfil atualizado com sucesso!');
        await _loadMe();
      } else {
        _show('Erro ao atualizar perfil (${resp.statusCode})');
      }
    } catch (e) {
      _show('Erro: $e');
    } finally {
      setState(() => saving = false);
    }
  }

  Future<void> _inativarConta() async {
    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Inativar conta'),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Inativar')),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final motivo = motivoController.text.trim();
        final resp = await ApiService().put('users/me/status', {'motivo': motivo});

        if (resp.statusCode == 200) {
          _show('Conta inativada.');
          
          await Provider.of<AuthProvider>(context, listen: false).logout();

          if (!mounted) return;

          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        } else {
          _show('Erro: ${resp.body}');
        }
      } catch (e) {
        _show('Erro: $e');
      }
    }
  }

  void _show(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E4A8E),
        foregroundColor: const Color(0xFF4F3466),
        title: const Text('Perfil'),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F3466)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pick,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF947CAC),
                      backgroundImage: _avatar != null
                          ? FileImage(_avatar!)
                          : (avatarUrl != null
                              ? NetworkImage('${AppConfig.baseUrl}$avatarUrl')
                              : null) as ImageProvider?,
                      child: _avatar == null && avatarUrl == null
                          ? const Icon(Icons.camera_alt, color: Colors.white70, size: 36)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _field(_nome, 'Nome completo'),
                  const SizedBox(height: 12),
                  _field(_usuario, 'Nome de usuário'),
                  const SizedBox(height: 12),
                  _field(_email, 'E-mail'),
                  const SizedBox(height: 12),
                  _field(_senha, 'Nova senha', obscure: true),
                  const SizedBox(height: 12),
                  _field(_generos, 'Gêneros preferidos (separados por vírgula)'),

                  const SizedBox(height: 28),

                  saving
                      ? const CircularProgressIndicator(color: Color(0xFF4F3466))
                      : ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Alterações'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF947CAC),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: _inativarConta,
                    icon: const Icon(Icons.person_off),
                    label: const Text('Inativar minha conta'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Color(0xFF4F3466), width: 2),
                      foregroundColor: const Color(0xFF4F3466),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFCABCD7),
        labelStyle: const TextStyle(color: Color(0xFF4F3466)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF947CAC)),
        ),
      ),
    );
  }
}
