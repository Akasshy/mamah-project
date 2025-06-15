import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ibu/skrining/question_page.dart';
import 'package:health_app/ibu/skrining/rekomendasi_page.dart';
import 'package:health_app/ibu/skrining/show_score_page.dart';

class SkriningsPage extends StatelessWidget {
  const SkriningsPage({Key? key}) : super(key: key); // Added Key? key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wrap with Scaffold
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: Colors.white,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Text di kiri
                    const Text(
                      'Skrining',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    // Profil kanan
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: AppColors
            .background, // Menggunakan warna latar belakang dari AppColors
        padding: const EdgeInsets.symmetric(horizontal: 0),
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _MenuCard(
                title: item.title,
                icon: item.icon,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => item.page),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.inputFill : AppColors.background,
              borderRadius: BorderRadius.circular(0),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withOpacity(0.05),
              //     blurRadius: 8,
              //     offset: const Offset(0, 2),
              //   ),
              // ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: 48,
                  height: 48,
                  child: Icon(
                    widget.icon,
                    color: AppColors.inputBorderFocused,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final Widget page;

  const MenuItem({required this.title, required this.icon, required this.page});
}

final List<MenuItem> menuItems = [
  MenuItem(
    title: 'Isi Kuesioner EPDS',
    icon: Icons.assignment_turned_in_rounded,
    page: const QuestionPage(),
  ),
  MenuItem(
    title: 'Lihat Hasil Skor',
    icon: Icons.bar_chart_rounded,
    page: const LihatSkor(),
  ),
  MenuItem(
    title: 'Rekomendasi',
    icon: Icons.recommend_rounded,
    page: const RekomendasiPage(),
  ),
];

// Dummy pages
// class HasilSkorPage extends StatelessWidget {
//   const HasilSkorPage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       const Center(child: Text("Halaman Hasil Skor"));
// }
