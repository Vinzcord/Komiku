import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../class/kategori.dart';
import 'login.dart';

class BuatKomikScreen extends StatefulWidget {
  const BuatKomikScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _BuatKomikScreenState();
  }
}

class _BuatKomikScreenState extends State<BuatKomikScreen> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _picker = ImagePicker();

  File? _posterFile;
  final List<File> _halamanFiles = [];
  List<Kategori> kategoriList = [];
  final Set<int> kategoriTerpilih = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    bacaKategori();
  }

  Future<void> bacaKategori() async {
    final response = await http.post(Uri.parse("$baseUrl/kategorilist.php"));
    Map json = jsonDecode(response.body);
    if (json['result'] == 'success') {
      setState(() {
        kategoriList = (json['data'] as List).map((e) => Kategori.fromJson(e)).toList();
      });
    }
  }

  Future<void> pilihPoster() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _posterFile = File(picked.path));
  }

  Future<void> pilihHalaman() async {
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() => _halamanFiles.addAll(picked.map((e) => File(e.path))));
    }
  }

  // Upload 1 file gambar dalam bentuk base64, kembalikan URL hasil upload
  Future<String?> uploadGambar(File file, String jenis) async {
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final ext = file.path.split('.').last;

    final endpoint = jenis == 'poster' ? 'uploadposter64.php' : 'uploadhalaman64.php';
    final fieldName = jenis == 'poster' ? 'poster_base64' : 'halaman_base64';

    final response = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      body: {fieldName: base64Str, 'ext': ext},
    );
    Map json = jsonDecode(response.body);
    if (json['result'] == 'success') {
      return json['url'];
    }
    return null;
  }

  Future<void> simpanKomik() async {
    if (_judulController.text.trim().isEmpty) {
      _showMessage('Judul komik wajib diisi');
      return;
    }
    if (kategoriTerpilih.isEmpty) {
      _showMessage('Pilih minimal 1 kategori');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null) {
      _showMessage('Silakan login terlebih dahulu');
      return;
    }

    setState(() => _isSubmitting = true);

    String posterUrl = '';
    if (_posterFile != null) {
      posterUrl = await uploadGambar(_posterFile!, 'poster') ?? '';
    }

    // buat komik dulu
    final resKomik = await http.post(
      Uri.parse("$baseUrl/newkomik.php"),
      body: {
        'judul': _judulController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'poster': posterUrl,
        'user_id': userId,
        'kategori_ids': kategoriTerpilih.join(','),
      },
    );
    Map jsonKomik = jsonDecode(resKomik.body);

    if (jsonKomik['result'] != 'success') {
      setState(() => _isSubmitting = false);
      _showMessage(jsonKomik['message'] ?? 'Gagal membuat komik');
      return;
    }

    final komikId = jsonKomik['komik_id'];

    // upload semua halaman lalu buat chapter 1
    if (_halamanFiles.isNotEmpty) {
      List<String> urls = [];
      for (final file in _halamanFiles) {
        final url = await uploadGambar(file, 'halaman');
        if (url != null) urls.add(url);
      }

      await http.post(
        Uri.parse("$baseUrl/newchapter.php"),
        body: {
          'komik_id': komikId.toString(),
          'chapter_number': '1',
          'judul': 'Chapter 1',
          'halaman_urls': urls.join(';'),
        },
      );
    }

    setState(() => _isSubmitting = false);
    _showMessage('Komik berhasil dibuat!');
    if (mounted) Navigator.pop(context);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Komik')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _judulController,
            decoration: const InputDecoration(labelText: 'Judul Komik'),
          ),
          TextFormField(
            controller: _deskripsiController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
          ),
          const SizedBox(height: 16),
          const Text('Poster Komik', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: pilihPoster,
            child: Container(
              height: 160,
              width: 120,
              color: Colors.grey.shade200,
              child: _posterFile != null
                  ? Image.file(_posterFile!, fit: BoxFit.cover)
                  : const Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: kategoriList.map((k) {
              final selected = kategoriTerpilih.contains(k.kategoriId);
              return FilterChip(
                label: Text(k.kategoriNama),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      kategoriTerpilih.add(k.kategoriId);
                    } else {
                      kategoriTerpilih.remove(k.kategoriId);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Halaman Komik', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(onPressed: pilihHalaman, icon: const Icon(Icons.add), label: const Text('Tambah')),
            ],
          ),
          if (_halamanFiles.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemCount: _halamanFiles.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Image.file(_halamanFiles[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _halamanFiles.removeAt(index)),
                        child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: simpanKomik, child: const Text('Terbitkan Komik')),
        ],
      ),
    );
  }
}
