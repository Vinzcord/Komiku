import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'kategori.dart';

const String baseUrl = "https://ubaya.cloud/flutter/160423098";

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LoginState();
  }
}

class _LoginState extends State<Login> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userNameController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isLoading = false;

  Future<void> doLogin() async {
    setState(() => _isLoading = true);

    final response = await http.post(
      Uri.parse("$baseUrl/komikku/login.php"),
      body: {
        'username': _userIdController.text,
        'password': _passwordController.text,
      },
    );

    Map json = jsonDecode(response.body);

    setState(() => _isLoading = false);

    if (json['status'] == 'success') {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('username', json['data']['username']);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KategoriScreen()),
        );
      }
    } else {
      _showMessage(json['message']);
    }
  }

  Future<void> doRegister() async {
    setState(() => _isLoading = true);
    final response = await http.post(
      Uri.parse("$baseUrl/register.php"),
      body: {
        'user_id': _userIdController.text,
        'password': _passwordController.text,
        'username': _userNameController.text,
      },
    );

    Map json = jsonDecode(response.body);
    setState(() => _isLoading = false);

    if (json['result'] == 'success') {
      setState(() => _isRegisterMode = false);
      _showMessage('Registrasi berhasil, silakan login');
    } else {
      _showMessage(json['message'] ?? 'Registrasi gagal');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Daftar Akun' : 'Login Komiku'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: <Widget>[
            const Icon(Icons.menu_book_rounded, size: 64),
            const SizedBox(height: 20),
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
            if (_isRegisterMode)
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _isRegisterMode ? doRegister : doLogin,
                    child: Text(_isRegisterMode ? 'Daftar' : 'Login'),
                  ),
            TextButton(
              onPressed: () =>
                  setState(() => _isRegisterMode = !_isRegisterMode),
              child: Text(
                _isRegisterMode
                    ? 'Sudah punya akun? Login'
                    : 'Belum punya akun? Daftar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
