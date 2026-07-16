class Kategori {
  int kategoriId;
  String kategoriNama;

  Kategori({required this.kategoriId, required this.kategoriNama});

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      kategoriId: int.parse(json['id'].toString()),
      kategoriNama: json['name'],
    );
  }
}
