import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../class/kategori.dart';
import 'login.dart';
import 'daftarkomik.dart';
import 'carikomik.dart';
import 'buatkomik.dart';

class KategoriScreen extends StatefulWidget {
  const KategoriScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _KategoriScreenState();
  }
}

class _KategoriScreenState extends State<KategoriScreen> {
  List<Kategori> kategoriList = [];

  Future<String> fetchData() async {
    final response = await http.post(Uri.parse("$baseUrl/kategorilist.php"));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to read API');
    }
  }

  Future<void> bacaData() async {
    Future<String> data = fetchData();
    data.then((value) {
      Map json = jsonDecode(value);
      kategoriList.clear();
      if (json['result'] == 'success') {
        for (var kat in json['data']) {
          kategoriList.add(Kategori.fromJson(kat));
        }
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    bacaData();
  }

  Widget daftarKategori() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: kategoriList.length,
      itemBuilder: (BuildContext ctxt, int index) {
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DaftarKomikScreen(kategori: kategoriList[index]),
                ),
              );
            },
            child: Center(
              child: Text(
                kategoriList[index].kategoriNama,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Komik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CariKomikScreen()));
            },
          ),
        ],
      ),
      body: kategoriList.isNotEmpty ? daftarKategori() : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BuatKomikScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Buat Komik'),
      ),
    );
  }
}
