import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../class/komik.dart';
import 'bacakomik.dart';
import 'login.dart';

class CariKomikScreen extends StatefulWidget {
  const CariKomikScreen({super.key});

  @override
  State<CariKomikScreen> createState() => _CariKomikScreenState();
}

class _CariKomikScreenState extends State<CariKomikScreen> {
  List<Komik> allKomik = [];
  List<Komik> komikList = [];

  final TextEditingController txtCari = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadKomik();
  }

  Future<void> loadKomik() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/komikku/get_all_komik.php"),
      );

      Map<String, dynamic> json = jsonDecode(response.body);

      allKomik.clear();
      if (json["status"] == "success") {
        for (var item in json["data"]) {
          allKomik.add(Komik.fromJson(item));
        }

        komikList = List.from(allKomik);
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        loading = false;
      });
    }
  }

  void cariKomik(String keyword) {
    keyword = keyword.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        komikList = List.from(allKomik);
      } else {
        komikList = allKomik.where((komik) {
          return komik.judul.toLowerCase().contains(keyword);
        }).toList();
      }
    });
  }

  Widget hasilCari() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (komikList.isEmpty) {
      return const Center(
        child: Text("Komik tidak ditemukan", style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      itemCount: komikList.length,
      itemBuilder: (context, index) {
        final komik = komikList[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                komik.poster,
                width: 60,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 60,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image),
                  );
                },
              ),
            ),
            title: Text(
              komik.judul,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(komik.author), Text("⭐ ${komik.rating}")],
            ),
            trailing: Text("💬 ${komik.jumlahKomentar}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BacaKomikScreen(komik: komik),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    txtCari.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cari Komik")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: txtCari,
              onChanged: cariKomik,
              decoration: const InputDecoration(
                hintText: "Cari judul komik...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: hasilCari()),
        ],
      ),
    );
  }
}
