import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../class/komik.dart';
import '../class/komentar.dart';
import 'login.dart';

class BacaKomikScreen extends StatefulWidget {
  final int komikId;
  const BacaKomikScreen({super.key, required this.komikId});

  @override
  State<StatefulWidget> createState() {
    return _BacaKomikScreenState();
  }
}

class _BacaKomikScreenState extends State<BacaKomikScreen> with SingleTickerProviderStateMixin {
  Komik? komik;
  List<Komentar> komentarList = [];
  int myRating = 0;
  String? myUserId;
  final _commentController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadUserId();
    bacaDetail();
    bacaKomentar();
  }

  Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => myUserId = prefs.getString('user_id'));
  }

  Future<void> bacaDetail() async {
    final response = await http.post(
      Uri.parse("$baseUrl/detailkomik.php"),
      body: {'komik_id': widget.komikId.toString()},
    );
    Map json = jsonDecode(response.body);
    if (json['result'] == 'success') {
      setState(() => komik = Komik.fromJson(json['data']));
    }
  }

  Future<void> bacaKomentar() async {
    final response = await http.post(
      Uri.parse("$baseUrl/commentlist.php"),
      body: {'komik_id': widget.komikId.toString()},
    );
    Map json = jsonDecode(response.body);
    if (json['result'] == 'success') {
      setState(() {
        komentarList = (json['data'] as List).map((e) => Komentar.fromJson(e)).toList();
      });
    }
  }

  Future<void> kirimRating(int skor) async {
    if (myUserId == null) {
      _showLoginRequired();
      return;
    }
    setState(() => myRating = skor);
    await http.post(
      Uri.parse("$baseUrl/addrating.php"),
      body: {
        'komik_id': widget.komikId.toString(),
        'user_id': myUserId!,
        'skor': skor.toString(),
      },
    );
    bacaDetail();
  }

  Future<void> kirimKomentar() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (myUserId == null) {
      _showLoginRequired();
      return;
    }
    await http.post(
      Uri.parse("$baseUrl/addcomment.php"),
      body: {
        'komik_id': widget.komikId.toString(),
        'user_id': myUserId!,
        'isi': text,
      },
    );
    _commentController.clear();
    bacaKomentar();
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Silakan login terlebih dahulu')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (komik == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(komik!.judul, overflow: TextOverflow.ellipsis),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Baca'),
          Tab(text: 'Komentar'),
        ]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [tabBaca(), tabKomentar()],
      ),
    );
  }

  Widget tabBaca() {
    final halaman = komik!.chapters.isNotEmpty ? komik!.chapters.first.halaman : <Halaman>[];
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(komik!.author != null ? 'oleh ${komik!.author}' : ''),
              const Spacer(),
              const Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
              Text(' ${komik!.viewCount}  '),
              const Icon(Icons.comment, size: 16, color: Colors.grey),
              Text(' ${komik!.commentCount}'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text('Rating: ${komik!.avgRating > 0 ? komik!.avgRating : "-"} (${komik!.ratingCount})'),
              const Spacer(),
              ...List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(star <= myRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 22),
                  onPressed: () => kirimRating(star),
                );
              }),
            ],
          ),
        ),
        const Divider(),
        if (halaman.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text('Belum ada halaman komik')),
          )
        else
          ...halaman.map((h) => Image.network(
                h.imageUrl,
                fit: BoxFit.fitWidth,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(height: 200, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
              )),
      ],
    );
  }

  Widget tabKomentar() {
    return Column(
      children: [
        Expanded(
          child: komentarList.isEmpty
              ? const Center(child: Text('Belum ada komentar'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: komentarList.length,
                  itemBuilder: (context, index) => komentarItem(komentarList[index]),
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: 'Tulis komentar...'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: kirimKomentar),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget komentarItem(Komentar k, {bool isReply = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 28 : 0, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(k.isi),
          for (final r in k.replies) komentarItem(r, isReply: true),
        ],
      ),
    );
  }
}
