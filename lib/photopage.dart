import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'foto.dart';
import 'fullscreenphotopage.dart';

class PhotoPage extends StatefulWidget {
  final int albumId;
  final String namaAlbum;

  const PhotoPage({super.key, required this.albumId, required this.namaAlbum});

  @override
  PhotoPageState createState() => PhotoPageState();
}

class PhotoPageState extends State<PhotoPage> {
  late Future<List<Foto>> _futurePhotos; // Perbaiki tipe data

  @override
  void initState() {
    super.initState();
    _futurePhotos = fetchPhotos(widget.albumId.toString()); // Tambahkan parameter
  }

  Future<List<Foto>> fetchPhotos(String albumId) async {
    try {
      final String apiUrl = "http://192.168.6.205/getphotos.php?AlbumID=$albumId";

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Pastikan JSON memiliki key 'photos'
        if (data['photos'] != null && data['photos'] is List) {
          return (data['photos'] as List)
              .map((photoJson) => Foto.fromJson(photoJson))
              .toList();
        } else {
          debugPrint('Format JSON tidak sesuai, "photos" tidak ditemukan');
          return [];
        }
      } else {
        debugPrint('Gagal mengambil foto, status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error saat mengambil foto: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.namaAlbum),
      ),
      body: FutureBuilder<List<Foto>>(
        future: _futurePhotos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _errorWidget("Terjadi kesalahan saat mengambil foto.");
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _errorWidget("Tidak ada foto di album ini.");
          }

          final List<Foto> photos = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4, //
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final Foto photo = photos[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenPhotoPage(
                        photoUrl: photo.lokasiFile,
                        userId: photo.userId, // Pastikan ini ada di model Foto
                        caption: photo.deskripsi, // Pastikan ini ada di model Foto
                        fotoId: photo.fotoid.toString(), // Pastikan ini benar
                      ),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photo.lokasiFile,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes !=null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              :null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 40, color: Colors.red),
                       );
                      },
                      ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      }


  /// 🔹 **Tambahkan metode ini untuk menangani error UI**
  Widget _errorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}
