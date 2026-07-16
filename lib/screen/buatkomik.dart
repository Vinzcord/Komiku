import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../class/kategori.dart';
import 'login.dart';

class BuatKomikScreen extends StatefulWidget {
  const BuatKomikScreen({super.key});

  @override
  State<BuatKomikScreen> createState() => _BuatKomikScreenState();
}

class _BuatKomikScreenState extends State<BuatKomikScreen> {
  final TextEditingController judulController = TextEditingController();
  final TextEditingController posterController = TextEditingController();

  List<TextEditingController> halamanController = [TextEditingController()];

  List<Kategori> kategoriList = [];
  Set<int> kategoriTerpilih = {};

  bool loading = false;

  @override
  void initState() {
    super.initState();
    bacaKategori();
  }

  Future<void> bacaKategori() async {
    final response = await http.post(
      Uri.parse("$baseUrl/komikku/get_all_kategori.php"),
    );

    Map json = jsonDecode(response.body);

    if (json["status"] == "success") {
      kategoriList = (json["data"] as List)
          .map((e) => Kategori.fromJson(e))
          .toList();

      setState(() {});
    }
  }

  Future<void> simpanKomik() async {
    if (judulController.text.trim().isEmpty) {
      tampilPesan("Judul wajib diisi");
      return;
    }

    if (posterController.text.trim().isEmpty) {
      tampilPesan("Poster wajib diisi");
      return;
    }

    if (kategoriTerpilih.isEmpty) {
      tampilPesan("Pilih minimal satu kategori");
      return;
    }

    List<String> daftarGambar = [];

    for (var c in halamanController) {
      if (c.text.trim().isNotEmpty) {
        daftarGambar.add(c.text.trim());
      }
    }

    if (daftarGambar.isEmpty) {
      tampilPesan("Minimal satu halaman");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String author = prefs.getString("username") ?? "";

    setState(() {
      loading = true;
    });

    final response = await http.post(
      Uri.parse("$baseUrl/komikku/insert_komik.php"),
      body: {
        "judul": judulController.text,
        "poster": posterController.text,
        "author": author,
        "kategori_ids": jsonEncode(kategoriTerpilih.toList()),
        "daftar_gambar": jsonEncode(daftarGambar),
      },
    );

    print(response.body);

    Map json = jsonDecode(response.body);

    setState(() {
      loading = false;
    });

    if (json["status"] == "success") {
      tampilPesan("Komik berhasil dibuat");

      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      tampilPesan(json["message"]);
    }
  }

  void tampilPesan(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    judulController.dispose();
    posterController.dispose();

    for (var c in halamanController) {
      c.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Komik")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: judulController,
            decoration: const InputDecoration(
              labelText: "Judul Komik",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: posterController,
            decoration: const InputDecoration(
              labelText: "URL Poster",
              hintText: "https://...",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Kategori",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kategoriList.map((k) {
              return FilterChip(
                label: Text(k.kategoriNama),
                selected: kategoriTerpilih.contains(k.kategoriId),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      kategoriTerpilih.add(k.kategoriId);
                    } else {
                      kategoriTerpilih.remove(k.kategoriId);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 25),

          Row(
            children: [
              const Text(
                "Halaman Komik",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    halamanController.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Tambah"),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...List.generate(halamanController.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: halamanController[index],
                      decoration: InputDecoration(
                        labelText: "URL Halaman ${index + 1}",
                        hintText: "https://...",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),

                  if (halamanController.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          halamanController[index].dispose();
                          halamanController.removeAt(index);
                        });
                      },
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 25),

          loading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: simpanKomik,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Terbitkan Komik",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
