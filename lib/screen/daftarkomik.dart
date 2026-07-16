import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../class/kategori.dart';
import '../class/komik.dart';
import 'bacakomik.dart';
import 'login.dart';

class DaftarKomikScreen extends StatefulWidget {
  final Kategori kategori;

  const DaftarKomikScreen({super.key, required this.kategori});

  @override
  State<DaftarKomikScreen> createState() => _DaftarKomikScreenState();
}

class _DaftarKomikScreenState extends State<DaftarKomikScreen> {
  List<Komik> komikList = [];
  bool loading = true;

  Future<void> bacaData() async {

    try {
      final url = "$baseUrl/komikku/get_all_komik.php";

      print(url);

      final response = await http.post(
        Uri.parse(url),
        body: {"kategori_id": widget.kategori.kategoriId.toString()},
      );

      print("STATUS : ${response.statusCode}");
      print("BODY : ${response.body}");

      Map<String, dynamic> json = jsonDecode(response.body);

      komikList.clear();

      if (json["status"] == "success") {
        print("JUMLAH DATA API = ${json["data"].length}");

        for (var item in json["data"]) {
          print(item);

          try {
            Komik k = Komik.fromJson(item);
            komikList.add(k);
            print("BERHASIL : ${k.judul}");
          } catch (e) {
            print("ERROR PARSING");
            print(e);
          }
        }

      }

      loading = false;

      setState(() {});
    } catch (e, s) {
      print("ERROR : $e");
      print(s);

      loading = false;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    print("INITSTATE DAFTAR KOMIK");
    bacaData();
  }

  @override
  Widget build(BuildContext context) {
    print("BUILD DAFTAR KOMIK");
    return Scaffold(
      appBar: AppBar(title: Text(widget.kategori.kategoriNama)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : komikList.isEmpty
          ? const Center(child: Text("Belum ada komik"))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: komikList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) {
                Komik komik = komikList[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BacaKomikScreen(komik: komik),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            komik.poster,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            komik.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            komik.author,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                komik.rating.toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.comment,
                                color: Colors.blueGrey,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                komik.jumlahKomentar.toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
