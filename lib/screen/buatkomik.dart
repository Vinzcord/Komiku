import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  final ImagePicker picker = ImagePicker();

  XFile? posterFile;
  List<XFile> halamanFiles = [];

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

  Future<void> pilihPoster() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file != null) {
      setState(() {
        posterFile = file;
      });
    }
  }

  Future<void> pilihHalaman() async {
    final files = await picker.pickMultiImage(imageQuality: 80);

    if (files.isNotEmpty) {
      setState(() {
        halamanFiles.addAll(files);
      });
    }
  }

  Future<String?> uploadPoster() async {
    if (posterFile == null) return null;

    final bytes = await posterFile!.readAsBytes();

    print("Nama File : ${posterFile!.name}");
    print("Ext : ${posterFile!.name.split(".").last}");

    final response = await http.post(
      Uri.parse("$baseUrl/komikku/uploadposter64.php"),
      body: {
        "poster_base64": base64Encode(bytes),
        "ext": posterFile!.name.split(".").last,
      },
    );

    print("UPLOAD POSTER");
    print(response.body);

    Map json = jsonDecode(response.body);

    if (json["result"] == "success") {
      return json["url"];
    }

    return null;
  }

  Future<List<String>> uploadHalaman() async {
    List<String> hasil = [];

    for (XFile file in halamanFiles) {
      final bytes = await file.readAsBytes();

      final response = await http.post(
        Uri.parse("$baseUrl/komikku/uploadhalaman64.php"),
        body: {
          "halaman_base64": base64Encode(bytes),
          "ext": file.name.split(".").last,
        },
      );

      print("UPLOAD HALAMAN");
      print(response.body);

      Map json = jsonDecode(response.body);

      if (json["result"] == "success") {
        hasil.add(json["url"]);
      }
    }

    return hasil;
  }

  Future<void> simpanKomik() async {
    if (judulController.text.trim().isEmpty) {
      tampilPesan("Judul komik wajib diisi");
      return;
    }

    if (posterFile == null) {
      tampilPesan("Pilih poster terlebih dahulu");
      return;
    }

    if (kategoriTerpilih.isEmpty) {
      tampilPesan("Pilih minimal 1 kategori");
      return;
    }

    if (halamanFiles.isEmpty) {
      tampilPesan("Pilih minimal 1 halaman komik");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String author = prefs.getString("username") ?? "";

    setState(() {
      loading = true;
    });

    String? posterUrl = await uploadPoster();

    if (posterUrl == null) {
      setState(() {
        loading = false;
      });

      tampilPesan("Upload poster gagal");
      return;
    }

    List<String> daftarGambar = await uploadHalaman();

    if (daftarGambar.isEmpty) {
      setState(() {
        loading = false;
      });

      tampilPesan("Upload halaman gagal");
      return;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/komikku/insert_komik.php"),
      body: {
        "judul": judulController.text.trim(),
        "poster": posterUrl,
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
        Navigator.pop(context, true);
      }
    } else {
      tampilPesan(json["message"] ?? "Gagal membuat komik");
    }
  }

  void tampilPesan(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    judulController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Komik")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// Judul
          TextField(
            controller: judulController,
            decoration: const InputDecoration(
              labelText: "Judul Komik",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          /// Poster
          const Text(
            "Poster Komik",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 10),

          Center(
            child: GestureDetector(
              onTap: pilihPoster,
              child: Container(
                width: 180,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: posterFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50),
                          SizedBox(height: 10),
                          Text("Pilih Poster"),
                        ],
                      )
                    : FutureBuilder<Uint8List>(
                        future: posterFile!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          /// Kategori
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

          /// Halaman
          Row(
            children: [
              const Text(
                "Halaman Komik",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: pilihHalaman,
                icon: const Icon(Icons.add),
                label: const Text("Tambah"),
              ),
            ],
          ),

          const SizedBox(height: 10),

          halamanFiles.isEmpty
              ? Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Text("Belum ada halaman"),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: halamanFiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        FutureBuilder<Uint8List>(
                          future: halamanFiles[index].readAsBytes(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          },
                        ),

                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                halamanFiles.removeAt(index);
                              });
                            },
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

          const SizedBox(height: 30),

          loading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: simpanKomik,
                    icon: const Icon(Icons.upload),
                    label: const Text("Terbitkan Komik"),
                  ),
                ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
