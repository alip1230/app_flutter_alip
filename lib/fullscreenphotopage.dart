import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FullScreenPhotoPage extends StatefulWidget {
  final String photoUrl;
  final String userId;
  final String caption;
  final String fotoId; // Tambahkan FotoID sebagai parameter

  const FullScreenPhotoPage({
    super.key,
    required this.photoUrl,
    required this.userId,
    required this.caption,
    required this.fotoId, // Terima FotoID dari halaman sebelumnya
  });

  @override
  _FullScreenPhotoPageState createState() => _FullScreenPhotoPageState();
}

class _FullScreenPhotoPageState extends State<FullScreenPhotoPage> {
  String username = "Loading..."; // Default sebelum data di-load
  String judulFoto = "Loading..."; // Menampung JudulFoto dari database
  String deskripsiFoto = "Loading..."; // Menampung DeskripsiFoto dari database

  @override
  void initState() {
    super.initState();
    fetchUsername();
    debugPrint("FotoID yang diterima: ${widget.fotoId}"); // Debug FotoID
    fetchPhotoDetails(); // 🔹 Panggil fungsi untuk ambil Judul & Deskripsi Foto
  }

  // 🔹 Fungsi untuk mengambil Username (Tidak diubah)
  Future<void> fetchUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('UserID'); // Ambil UserID dari SharedPreferences

    if (userId == null) {
      setState(() => username = "Unknown User");
      return;
    }

    final url = Uri.parse('http://192.168.6.205/getuser.php?UserID=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => username = data['Username'] ?? "Unknown User");
      } else {
        setState(() => username = "Unknown User");
      }
    } catch (e) {
      setState(() => username = "Unknown User");
    }
  }

  Future<void> fetchPhotoDetails() async {
    if (widget.fotoId.isEmpty) {
      debugPrint("Error: FotoID kosong!");
      setState(() {
        judulFoto = "Invalid FotoID";
        deskripsiFoto = "Invalid FotoID";
      });
      return;
    }

    final url = Uri.parse('http://192.168.6.205/getphoto.php?FotoID=${widget.fotoId}');
    debugPrint("Fetching photo details from: $url");

    try {
      final response = await http.get(url);

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("Decoded Response: $data");

        setState(() {
          judulFoto = data['JudulFoto'] ?? "No Title";
          deskripsiFoto = data['DeskripsiFoto'] ?? "No Description";
        });
      } else {
        debugPrint("Error fetching photo details: ${response.statusCode}");
        setState(() {
          judulFoto = "Error loading title";
          deskripsiFoto = "Error loading description";
        });
      }
    } catch (e) {
      debugPrint("Exception: $e");
      setState(() {
        judulFoto = "Error loading title";
        deskripsiFoto = "Error loading description";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🔹 Gambar utama
          Center(
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity, // Full width
                  child: AspectRatio(
                    aspectRatio: 4 / 6, // Sesuaikan rasio dengan tampilan album
                    child: Image.network(
                      widget.photoUrl,
                      fit: BoxFit.cover, // Mengisi sesuai ukuran tanpa distorsi
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 50, color: Colors.red),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Tombol kembali di pojok kiri atas
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // 🔹 Navigasi Like & Comment di bagian bawah
          Positioned(
            bottom: -15,
            left: 10,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Like dan Komen
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border,color: Colors.black, size: 25),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon:const Icon(Icons.mode_comment_outlined, color: Colors.black, size: 25),
                      onPressed: () {},
                    ),
                  ],
                ),
                // 🟢 Username
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),

                // 🟠 Judul Foto (di bawah Username)
                Text(
                  judulFoto,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 4),

                // 🔵 Deskripsi Foto (di bawah Judul Foto)
                Text(
                  deskripsiFoto,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
            const SizedBox(height: 10), // spasi antara despripsi dan ikon
              ],
            ),
          ),
        ],
      ),
    );
  }
}
