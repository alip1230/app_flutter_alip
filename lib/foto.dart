class Foto {
final String fotoid;
final String judul;
final String deskripsi;
final String lokasiFile;
final String tanggalUnggah;
final String albumId;
final String userId;

Foto({
  required this.fotoid,
  required this.judul,
  required this.deskripsi,
  required this.lokasiFile,
  required this.tanggalUnggah,
  required this.albumId,
  required this.userId,
});

// Factory method untuk membuat instance dari JSON
factory Foto.fromJson(Map<String, dynamic> json) {
return Foto(
fotoid: json['FotoID'] ?? '',
judul: json['JudulFoto'] ?? 'Tanpa Judul',
deskripsi: json['DeskripsiFoto'] ?? 'Tanpa Deskripsi',
lokasiFile: json['LokasiFile'] ?? '',
tanggalUnggah: json['TanggalUnggah'] ?? '',
albumId: json['AlbumID'] ?? '',
userId: json['UserID'] ?? '',
);
}
}