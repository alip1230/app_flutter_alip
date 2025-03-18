import 'package:flutter/material.dart';
import 'dart:io'; // Untuk upload via perangkat selain Web
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  UploadPageState createState() => UploadPageState();
}

class UploadPageState extends State<UploadPage> {
  Uint8List? imageBytes;
  File? imageFile; // Untuk perangkat selain Web
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? userId;
  bool isUploading = false;

  List<dynamic> albums = [];
  int? selectedAlbumId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('UserID');
    if (id != null) {
      setState(() {
        userId = id;
      });
      debugPrint('UserID ditemukan: $userId');
      _fetchAlbums(); // Fetch albums setelah UserID ditemukan
    } else {
      debugPrint('User ID tidak ditemukan di SharedPreferences');
    }
  }

  Future<void> _fetchAlbums() async {
    if (userId == null) return;

    final String apiUrl = "http://192.168.6.205/getalbums.php?UserID=$userId";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            albums = data['albums'];
          });
          debugPrint('Album berhasil diambil: ${data['albums']}');
        } else {
          debugPrint('Gagal mengambil daftar album: ${data['message']}');
        }
      } else {
        debugPrint('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saat mengambil album: $e');
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      debugPrint('Gambar berhasil dipilih: ${pickedFile.name}');
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          imageBytes = bytes;
          imageFile = null;
        });
      } else {
        setState(() {
          imageFile = File(pickedFile.path);
          imageBytes = null;
        });
      }
    } else {
      debugPrint('Tidak ada gambar yang dipilih.');
    }
  }

  Future<void> uploadImage() async {
    debugPrint('Mengirim permintaan upload...');

    if (imageFile == null && imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada gambar yang dipilih')),
      );
      debugPrint('Upload gagal: Tidak ada gambar yang dipilih');
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID tidak ditemukan')),
      );
      debugPrint('Upload gagal: User ID tidak ditemukan');
      return;
    }

    if (selectedAlbumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih album terlebih dahulu')),
      );
      debugPrint('Upload gagal: Album belum dipilih');
      return;
    }

    final String apiUrl = "http://192.168.6.205/upload.php";
    final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    if (kIsWeb && imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes!,
        filename: 'upload.jpg',
      ));
      debugPrint('Menambahkan gambar dari web untuk diunggah.');
    } else if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile!.path,
      ));
      debugPrint('Menambahkan gambar dari perangkat untuk diunggah.');
    }

    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['UserID'] = userId!;
    request.fields['AlbumID'] = selectedAlbumId.toString();

    setState(() {
      isUploading = true;
    });

    try {
      debugPrint('Mengirim permintaan upload...');
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        debugPrint('Respon diterima: $data');

        if (data['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gambar berhasil diunggah')),
            );

          }
        } else {
          debugPrint('Upload gagal: ${data['message']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Upload gagal')),
            );
          }
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saat upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Gambar'),
      ),
      body: SingleChildScrollView( // Tambahkan ini
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            imageFile != null
                ? Image.file(
              imageFile!,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ) :
            const Text('Belum ada gambar yang dipilih'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // Warna normal tombol
                foregroundColor: Colors.white, // Warna teks saat normal
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Membuat sudut lebih halus
                ),
              ),
              child: const Text('Pilih Gambar'),
            ),
            const SizedBox(height: 10),
            DropdownButton<int>(
              value: selectedAlbumId,
              hint: const Text('Pilih Album'),
              onChanged: (int? value) {
                setState(() {
                  selectedAlbumId = value;
                });
              },
              items: albums.map((album) {
                return DropdownMenuItem<int>(
                  value: int.parse(album['AlbumID']), // Ubah String ke int
                  child: Text(album['NamaAlbum']),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isUploading ? null : uploadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // Warna normal tombol
                foregroundColor: Colors.white, // Warna teks saat normal
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Membuat sudut lebih halus
                ),
              ),
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
