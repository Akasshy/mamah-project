import 'package:flutter/material.dart';
import 'package:health_app/bidan/beranda_bidan.dart';
import 'package:health_app/bidan/skrining/skrinings_bidan.dart';
import 'package:health_app/ibu/beranda/beranda_page.dart';
import 'package:health_app/ibu/diskusi/diskusi_page.dart';
import 'package:health_app/ibu/konsultasi/konsultasi_page.dart';
import 'package:health_app/ibu/skrining/skrinings_page.dart';
import 'package:health_app/ibu/edukasi_page.dart';
import 'custom_scaffold.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  final String role; // Menambahkan parameter role
  const HomePage({
    super.key,
    this.initialIndex = 0,
    required this.role,
  }); // default Skrining

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  late List<Widget> _pages;

  int _konsultasiBadge = 0; // 👈 jumlah badge konsultasi

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Gunakan nilai dari constructor
    _initializePages(); // Inisialisasi halaman berdasarkan role

    // Simulasi jumlah badge (misalnya dari API, bisa diubah nanti)
    _konsultasiBadge = 12;
  }

  void _initializePages() {
    if (widget.role == 'ibu') {
      _pages = const [
        Beranda(),
        SkriningsPage(),
        EdukasiPage(),
        DiskusiPage(),
        KonsultasiPage(),
      ];
    } else if (widget.role == 'bidan') {
      _pages = const [
        BerandaBidan(),
        SkriningBidan(),
        EdukasiPage(),
        DiskusiPage(), // <--- Pastikan bukan DiskusiPage untuk bidan
        KonsultasiPage(), // <--- Pastikan juga ini KonsultasiBidan
      ];
    } else {
      _pages = const [Center(child: Text('Role tidak dikenal'))];
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedIndex: _selectedIndex,
      onNavTap: _onNavTap,
      body: _pages[_selectedIndex],
      consultationBadgeCount: _konsultasiBadge, // 👈 Tambahan badge di sini
    );
  }
}
