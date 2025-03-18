import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'albumpage.dart';
import 'profilepage.dart';
import 'uploadpage.dart';
import 'loginpage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Gallery App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Background default putih
      ),
      home: const InitialScreen(), // Tampilkan LoginPage jika belum login
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}
class _InitialScreenState extends State<InitialScreen> {
  bool isLoggedIn = false;

 @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

@override
  Widget build(BuildContext context) {
    if (isLoggedIn) {
      return const MainScreen(); // Jika login, masuk ke halaman utama
    } else {
      return const LoginPage(); // Jika belum login, tampilkan halaman login
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Menyimpan indeks halaman aktif

  // List halaman yang akan ditampilkan
  final List<Widget> _pages = [
    HomePage(), // Halaman 1
    UploadPage(),  // Halaman 2
    AlbumPage(),
    ProfilePage(),
  ];

  // Fungsi untuk menangani navigasi
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Menampilkan halaman sesuai index
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white, // Navbar juga putih
        currentIndex: _selectedIndex, // Indeks aktif
        onTap: _onItemTapped,         // Panggil fungsi saat diklik
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_in_picture),
            label: 'Album',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.black87, // Warna saat item aktif
        unselectedItemColor: Colors.grey, // Warna item tidak aktif
        showUnselectedLabels: true, // Tampilkan label item tidak aktif

      ),
    );
  }
}

