import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/login.dart';
import 'screen/kategori.dart';

void main() {
  runApp(const KomikuApp());
}

class KomikuApp extends StatelessWidget {
  const KomikuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Komiku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.pink, useMaterial3: true),
      home: const SplashDecider(),
    );
  }
}

// Cek apakah user sudah login lewat data yang tersimpan di SharedPreferences
class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SplashDeciderState();
  }
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    cekLogin();
  }

  Future<void> cekLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('username');
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => userId != null ? const KategoriScreen() : const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
