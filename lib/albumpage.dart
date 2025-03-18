import 'dart:developer';
import 'dart:convert';
import 'package:alip_app/foto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'album.dart';
import 'photopage.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('UserID');
    if (userId == null) {
      log('User ID tidak ditemukan di SharedPreferences');
      // Navigate to login page if user is not logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(
            '/login'); // Adjust route name as needed
      });
    } else {
      log('User ID ditemukan: $userId');
    }
    return userId;
  }

  Future<List<Album>> fetchAlbums() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        log(
            'User ID tidak ditemukan, tidak dapat melanjutkan pengambilan album');
        return [];
      }

      final String apiUrl = "http://192.168.6.205/getalbums.php?UserID=$userId";

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        log('Berhasil mengambil data album');
        final data = json.decode(response.body);
        if (data['albums'] != null) {
          return (data['albums'] as List)
              .map((albumJson) => Album.fromJson(albumJson))
              .toList();
        } else {
          log('Data album kosong atau format tidak sesuai');
          return [];
        }
      } else {
        log('Gagal mengambil album, status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error saat mengambil album: $e');
      return [];
    }
  }

  Future<void> _tambahAlbum(String nama, String deskripsi) async {
    try {
      final userId = await getUserId();
      if (userId == null) return;

      final String apiUrl = "http://192.168.6.205/addalbum.php";
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'UserID': userId,
          'NamaAlbum': nama,
          'Deskripsi': deskripsi,
        }),
      );

      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      final responseData = json.decode(response.body);
      if (responseData['success']) {
        log("Album berhasil ditambahkan!");
        setState(() {}); // Refresh halaman
      } else {
        log("Gagal menambah album: ${responseData['message']}");
      }
    } catch (e) {
      log("Error: $e");
    }
  }

  void _showTambahAlbumDialog() {
    TextEditingController namaController = TextEditingController();
    TextEditingController deskripsiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Album'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Album'),
              ),
              TextField(
                controller: deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                _tambahAlbum(namaController.text, deskripsiController.text);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album Foto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showTambahAlbumDialog,
          ),
              IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<List<Album>>(
        future: fetchAlbums(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_album_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text('Tidak ada album'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final List<Album> albums = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final Album album = albums[index];
              return GestureDetector(
                onTap: () {
                  // Navigasi ke halaman foto, kirimkan albumId dan namaAlbum sebagai argumen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PhotoPage(
                        albumId: album.albumId,
                        namaAlbum: album.namaAlbum,
                      ),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: album.sampulAlbum != null
                              ? Image.network(
                            album.sampulAlbum!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                      null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              log('Error loading image: $error');
                              return const Center(
                                child: Icon(
                                    Icons.error, size: 40, color: Colors.red),
                              );
                            },
                          )
                              : const Center(
                            child: Icon(Icons.photo_album, size: 40,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.namaAlbum,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              album.deskripsi,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}