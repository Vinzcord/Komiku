import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../class/kategori.dart';
import '../class/komik.dart';
import 'login.dart';
import 'bacakomik.dart';

class DaftarKomikScreen extends StatefulWidget {
  final Kategori kategori;
  const DaftarKomikScreen({super.key, required this.kategori});

  @override
  State<StatefulWidget> createState() {
    return _DaftarKomikScreenState();
  }
}

class _DaftarKomikScreenState extends State<DaftarKomikScreen> {
  List<Komik> komikList = [];

  Future<String> fetchData() async {
    final response = await http.post(
      Uri.parse("$baseUrl/komiklist.php"),
      body: {'kategori_id': widget.kategori.kategoriId.toString()},
    );
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
      komikList.clear();
      if (json['result'] == 'success') {
        for (var kom in json['data']) {
          komikList.add(Komik.fromJson(kom));
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

  Widget daftarKomik() {
    if (komikList.isEmpty) {
      return const Center(child: Text('Belum ada komik di kategori ini'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: komikList.length,
      itemBuilder: (BuildContext ctxt, int index) {
        final komik = komikList[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BacaKomikScreen(komikId: komik.komikId)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: komik.poster != null && komik.poster!.isNotEmpty
                    ? Image.network(komik.poster!, fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image)))
                    : Container(color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported)),
              ),
              const SizedBox(height: 4),
              Text(komik.judul, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  Text(' ${komik.avgRating > 0 ? komik.avgRating : "-"}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  const Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
                  Text(' ${komik.viewCount}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.kategori.kategoriNama)),
      body: daftarKomik(),
    );
  }
}
