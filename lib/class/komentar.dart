class Komentar {
  int id;
  String isi;
  String userName;
  String waktu;

  Komentar({
    required this.id,
    required this.isi,
    required this.userName,
    required this.waktu,
  });

  factory Komentar.fromJson(Map<String, dynamic> json) {
    return Komentar(
      id: int.parse(json["id"].toString()),
      isi: json["isi"] ?? "",
      userName: json["username"] ?? "",
      waktu: json["waktu"] ?? "",
    );
  }
}
