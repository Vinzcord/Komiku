class Komentar {
  int komentarId;
  int komikId;
  String userId;
  String userName;
  int? parentId;
  String isi;
  String createdAt;
  List<Komentar> replies;

  Komentar({
    required this.komentarId,
    required this.komikId,
    required this.userId,
    required this.userName,
    this.parentId,
    required this.isi,
    required this.createdAt,
    this.replies = const [],
  });

  factory Komentar.fromJson(Map<String, dynamic> json) {
    return Komentar(
      komentarId: int.parse(json['komentar_id'].toString()),
      komikId: int.parse(json['komik_id'].toString()),
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? '',
      parentId: json['parent_id'] != null ? int.parse(json['parent_id'].toString()) : null,
      isi: json['isi'] ?? '',
      createdAt: json['created_at'] ?? '',
      replies: (json['replies'] as List? ?? []).map((e) => Komentar.fromJson(e)).toList(),
    );
  }
}
