import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../class/komik.dart';
import '../class/komentar.dart';
import 'login.dart';

class BacaKomikScreen extends StatefulWidget {
  final Komik komik;

  const BacaKomikScreen({super.key, required this.komik});

  @override
  State<BacaKomikScreen> createState() => _BacaKomikScreenState();
}

class _BacaKomikScreenState extends State<BacaKomikScreen> {
  List<String> gambar = [];
  List<Komentar> komentar = [];

  double rating = 0;

  String username = "";

  final TextEditingController txtKomentar = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUser();
    getGambar();
    getKomentar();
    getRating();
  }

  Future<void> loadUser() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    username = pref.getString("username") ?? "";
  }

  Future<void> getGambar() async {
    final response = await http.post(
      Uri.parse("$baseUrl/komikku/get_gambar_komik.php"),
      body: {"komik_id": widget.komik.id.toString()},
    );

    Map json = jsonDecode(response.body);

    if (json["status"] == "success") {
      gambar.clear();

      for (var g in json["data"]) {
        gambar.add(g["url"]);
      }

      setState(() {});
    }
  }

  Future<void> getKomentar() async {
    final response = await http.post(
      Uri.parse("$baseUrl/komikku/get_komentar_komik.php"),
      body: {"komik_id": widget.komik.id.toString()},
    );

    Map json = jsonDecode(response.body);

    if (json["status"] == "success") {
      komentar = (json["data"] as List)
          .map((e) => Komentar.fromJson(e))
          .toList();

      setState(() {});
    }
  }

  Future<void> getRating() async {
    final response = await http.post(
      Uri.parse("$baseUrl/komikku/get_rating_komik.php"),
      body: {"komik_id": widget.komik.id.toString()},
    );

    Map json = jsonDecode(response.body);

    if (json["status"] == "success") {
      rating = double.parse(json["rata_rating"].toString());

      setState(() {});
    }
  }

  Future<void> kirimKomentar() async {
    if (txtKomentar.text.trim().isEmpty) return;

    print("USERNAME : $username");
    print("KOMIK ID : ${widget.komik.id}");
    print("ISI : ${txtKomentar.text}");

    final response = await http.post(
      Uri.parse("$baseUrl/komikku/insert_komentar.php"),
      body: {
        "isi": txtKomentar.text,
        "user_username": username,
        "komik_id": widget.komik.id.toString(),
      },
    );

    print(response.body);

    txtKomentar.clear();

    await getKomentar();
  }

  Future<void> kirimRating(int value) async {
    await http.post(
      Uri.parse("$baseUrl/komikku/insert_rating.php"),
      body: {
        "user": username,
        "komik_id": widget.komik.id.toString(),
        "value": value.toString(),
      },
    );

    getRating();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.komik.judul)),
      body: ListView(
        children: [
          Image.network(widget.komik.poster, height: 250, fit: BoxFit.cover),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.komik.judul,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text("Author : ${widget.komik.author}"),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),

                Text(rating.toString()),

                const Spacer(),

                for (int i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () {
                      kirimRating(i);
                    },
                    icon: const Icon(Icons.star_border, color: Colors.amber),
                  ),
              ],
            ),
          ),

          const Divider(),

          ...gambar.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Image.network(e),
            );
          }).toList(),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Komentar",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          ...komentar.map((k) {
            return ListTile(title: Text(k.userName), subtitle: Text(k.isi));
          }).toList(),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: txtKomentar,
                    decoration: const InputDecoration(
                      hintText: "Tulis komentar...",
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    kirimKomentar();
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
