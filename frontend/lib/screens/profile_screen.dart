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
  File? _avatar;
  final ImagePicker _picker = ImagePicker();
  bool uploading = false;

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);

    // validação de tipo (sufixo) e tamanho (<= 2MB) — requisito solicitado
    final allowed = ['jpg','jpeg','png','webp'];
    final ext = picked.name.split('.').last.toLowerCase();
    final size = await file.length();
    if (!allowed.contains(ext)) {
      _show('Tipo de arquivo não permitido. Use JPG/PNG/WEBP.');
      return;
    }
    if (size > 2 * 1024 * 1024) {
      _show('Arquivo muito grande. Máximo 2MB.');
      return;
    }

    setState(()=>_avatar = file);
  }

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _upload() async {
    if (_avatar == null) { _show('Selecione uma imagem.'); return; }
    setState(()=>uploading=true);
    try {
      final res = await ApiService().uploadAvatar('users/me', _avatar!);
      if (res.statusCode == 200 || res.statusCode == 201) {
        _show('Avatar atualizado');
      } else {
        _show('Erro ao enviar. Código: ${res.statusCode}');
      }
    } catch (e) {
      _show('Erro: $e');
    } finally { setState(()=>uploading=false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(radius: 48, backgroundImage: _avatar != null ? FileImage(_avatar!) : null, child: _avatar == null ? const Icon(Icons.camera_alt) : null),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _upload, child: uploading ? const CircularProgressIndicator() : const Text('Enviar Avatar (max 2MB)'))
        ]),
      ),
    );
  }
}
