import 'main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'registerpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String message = '';
  bool isPasswordVisible = false; // Menentukan apakah password terlihat
  bool isLoading = false; // Untuk menampilkan indikator loading

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('UserID', userId);
    debugPrint('User ID berhasil disimpan: $userId');
  }

  Future<void> login() async {
    final String apiUrl = 'http://192.168.6.205/login.php';
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validasi masukan
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        message = 'Email dan password harus diisi.';
      });
      return;
    }

    setState(() {
      isLoading = true; // Tampilkan loading
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Data parsed from API: $data');

        if (data['success'] == true) {
          final user = data['user'];
          final userId = user != null ? user['UserID'] : null;

          debugPrint('User ID dari API: $userId');

          // Cek apakah userId tidak null sebelum menyimpan
          if (userId != null) {
            await saveUserId(userId.toString());
          } else {
            debugPrint('User ID dari API adalah null');
          }
          // Navigasi main screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        } else {
          // Login gagal
          setState(() {
            message = data['message'] ?? 'Login gagal. Periksa kembali kredensial Anda.';
          });
        }
      } else {
        setState(() {
          message = 'Terjadi kesalahan pada server. Coba lagi nanti.';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Gagal terhubung ke server.';
      });
      debugPrint('Error: $e');
    } finally {
      setState(() {
        isLoading = false; // Sembunyikan loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Masukkan email Anda',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible; // Toggle visibilitas
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const Center(child: CircularProgressIndicator()) // Indikator loading
                : ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text("Belum punya akun? Daftar di sini"),
            ),
          ],
        ),
      ),
    );
  }
}
