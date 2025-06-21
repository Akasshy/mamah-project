import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/bidan/beranda_bidan.dart';
import 'package:health_app/bidan/skrining/skrinings_bidan.dart';
import 'package:health_app/ibu/beranda/beranda_page.dart';
import 'package:health_app/ibu/diskusi/diskusi_page.dart';
import 'package:health_app/ibu/konsultasi/konsultasi_page.dart';
import 'package:health_app/ibu/skrining/skrinings_page.dart';
import 'package:health_app/ibu/edukasi_page.dart';
import 'package:health_app/custom_scaffold.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  final String role;

  const HomePage({super.key, this.initialIndex = 0, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  late List<Widget> _pages;
  int _konsultasiBadge = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initializePages();
    _konsultasiBadge = 12; // Simulated badge count
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
        DiskusiPage(),
        KonsultasiPage(),
      ];
    } else {
      _pages = [
        Center(
          child: Text(
            'Role tidak dikenali',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ),
      ];
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Untuk teks/ikon gelap
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: CustomScaffold(
        selectedIndex: _selectedIndex,
        onNavTap: _onNavTap,
        body: _pages[_selectedIndex],
        consultationBadgeCount: _konsultasiBadge,
      ),
    );
  }
}
