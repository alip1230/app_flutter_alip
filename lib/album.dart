class Album {
  final int albumId;
  final String namaAlbum;
  final String deskripsi;
  final String? sampulAlbum; // URL foto sampul (opsional)

  Album({
    required this.albumId,
    required this.namaAlbum,
    required this.deskripsi,
    this.sampulAlbum,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      albumId: int.parse(json['AlbumID']),
      namaAlbum: json['NamaAlbum'],
      deskripsi: json['Deskripsi'],
      sampulAlbum: json['SampulAlbum'], // Gunakan key dari API
    );
  }
}
