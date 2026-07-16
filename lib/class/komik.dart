class Komik {
  int id;
  String judul;
  String poster;
  String author;
  double rating;
  int jumlahKomentar;

  Komik({
    required this.id,
    required this.judul,
    required this.poster,
    required this.author,
    required this.rating,
    required this.jumlahKomentar,
  });

  factory Komik.fromJson(Map<String, dynamic> json) {
    return Komik(
      id: int.parse(json['id'].toString()),
      judul: json['judul'] ?? '',
      poster: json['poster'] ?? '',
      author: json['author'] ?? '',
      rating: double.parse(json['rating'].toString()),
      jumlahKomentar: int.parse(json['jumlah_komentar'].toString()),
    );
  }
}
