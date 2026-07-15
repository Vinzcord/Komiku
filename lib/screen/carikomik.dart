import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../class/komik.dart';
import 'login.dart';
import 'bacakomik.dart';

class CariKomikScreen extends StatefulWidget {
  const CariKomikScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CariKomikScreenState();
  }
}

class _CariKomikScreenState extends State<CariKomikScreen> {
  List<Komik> komikList = [];
  String _txtCari = '';

  Future<String> fetchData() async {
    final response = await http.post(
      Uri.parse("$baseUrl/komiklist.php"),
      body: {'cari': _txtCari},
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

  Widget daftarHasil() {
    if (komikList.isEmpty) {
      return const Center(child: Text('Tidak ada hasil'));
    }
    return ListView.builder(
      itemCount: komikList.length,
      itemBuilder: (BuildContext ctxt, int index) {
        final komik = komikList[index];
        return Card(
          child: ListTile(
            leading: komik.poster != null && komik.poster!.isNotEmpty
                ? Image.network(komik.poster!, width: 44, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported))
                : const Icon(Icons.menu_book),
            title: Text(komik.judul),
            subtitle: Text('Rating: ${komik.avgRating > 0 ? komik.avgRating : "-"}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BacaKomikScreen(komikId: komik.komikId)),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Komik')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              decoration: const InputDecoration(
                icon: Icon(Icons.search),
                labelText: 'Judul mengandung kata:',
              ),
              onFieldSubmitted: (value) {
                setState(() => _txtCari = value);
                komikList.clear();
                bacaData();
              },
            ),
          ),
          Expanded(child: daftarHasil()),
        ],
      ),
    );
  }
}
