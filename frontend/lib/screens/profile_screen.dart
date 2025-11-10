import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

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

  // Carrega usuário logado
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

  // Escolher avatar
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

  // Salvar alterações
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

  // Inativar conta
  Future<void> _inativarConta() async {
    final motivoController = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Inativar conta'),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final motivo = motivoController.text.trim();
        final api = ApiService();
        final resp = await api.put('users/me/status', {'motivo': motivo});

        if (resp.statusCode == 200) {
          _show('Conta inativada.');
          if (mounted) Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('Seu Perfil'),
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 6,
        shadowColor: Colors.purpleAccent.withOpacity(0.5),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.purple.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pick,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: _avatar != null
                                ? FileImage(_avatar!)
                                : (avatarUrl != null
                                    ? NetworkImage(
                                        'http://192.168.100.12:3000$avatarUrl')
                                    : null) as ImageProvider?,
                            child: _avatar == null && avatarUrl == null
                                ? const Icon(Icons.camera_alt,
                                    color: Colors.white70, size: 36)
                                : null,
                          ),
                          if (saving)
                            const CircularProgressIndicator(color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildField(_nome, 'Nome completo'),
                    const SizedBox(height: 12),
                    _buildField(_usuario, 'Nome de usuário'),
                    const SizedBox(height: 12),
                    _buildField(_email, 'E-mail'),
                    const SizedBox(height: 12),
                    _buildField(_senha, 'Nova senha', obscure: true),
                    const SizedBox(height: 12),
                    _buildField(_generos,
                        'Gêneros preferidos (separados por vírgula)'),
                    const SizedBox(height: 28),
                    saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent.shade200,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              shadowColor:
                                  Colors.purpleAccent.withOpacity(0.6),
                              elevation: 8,
                            ),
                            label: const Text(
                              'Salvar alterações',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _inativarConta,
                      icon: const Icon(Icons.person_off),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      label: const Text('Inativar minha conta'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label,
      {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
