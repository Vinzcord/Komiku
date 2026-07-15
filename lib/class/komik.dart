class Komik {
  int komikId;
  String judul;
  String? deskripsi;
  String? poster;
  String userId;
  String? author;
  int viewCount;
  double avgRating;
  int ratingCount;
  int commentCount;
  List<Chapter> chapters;

  Komik({
    required this.komikId,
    required this.judul,
    this.deskripsi,
    this.poster,
    required this.userId,
    this.author,
    this.viewCount = 0,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.commentCount = 0,
    this.chapters = const [],
  });

  factory Komik.fromJson(Map<String, dynamic> json) {
    return Komik(
      komikId: int.parse(json['komik_id'].toString()),
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'],
      poster: json['poster'],
      userId: json['user_id']?.toString() ?? '',
      author: json['author'],
      viewCount: int.parse((json['view_count'] ?? 0).toString()),
      avgRating: double.parse((json['avg_rating'] ?? 0).toString()),
      ratingCount: int.parse((json['rating_count'] ?? 0).toString()),
      commentCount: int.parse((json['comment_count'] ?? 0).toString()),
      chapters: (json['chapters'] as List? ?? []).map((e) => Chapter.fromJson(e)).toList(),
    );
  }
}

class Chapter {
  int chapterId;
  int chapterNumber;
  String? judul;
  List<Halaman> halaman;

  Chapter({required this.chapterId, required this.chapterNumber, this.judul, this.halaman = const []});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      chapterId: int.parse(json['chapter_id'].toString()),
      chapterNumber: int.parse(json['chapter_number'].toString()),
      judul: json['judul'],
      halaman: (json['halaman'] as List? ?? []).map((e) => Halaman.fromJson(e)).toList(),
    );
  }
}

class Halaman {
  int halamanId;
  int pageNumber;
  String imageUrl;

  Halaman({required this.halamanId, required this.pageNumber, required this.imageUrl});

  factory Halaman.fromJson(Map<String, dynamic> json) {
    return Halaman(
      halamanId: int.parse(json['halaman_id'].toString()),
      pageNumber: int.parse(json['page_number'].toString()),
      imageUrl: json['image_url'] ?? '',
    );
  }
}
