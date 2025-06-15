import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/profile.dart';

class CustomScaffold extends StatelessWidget {
  final Widget? body;
  final int selectedIndex;
  final Function(int) onNavTap;

  // Tambahan: jumlah badge pesan di Konsultasi (bisa statik dulu)
  final int consultationBadgeCount;

  const CustomScaffold({
    super.key,
    this.body,
    required this.selectedIndex,
    required this.onNavTap,
    this.consultationBadgeCount = 0, // default 0
  });

  static const List<Widget> bottomNavIcons = [
    Icon(Icons.home_sharp, size: 28),
    Icon(Icons.assignment_turned_in_sharp, size: 28),
    Icon(Icons.menu_book_sharp, size: 28),
    Icon(Icons.groups_sharp, size: 28),
    Icon(Icons.medical_services_sharp, size: 28),
  ];

  static const List<String> bottomNavLabels = [
    'Beranda',
    'Skrining',
    'Edukasi',
    'Diskusi',
    'Konsultasi',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            child: body ?? const SizedBox.shrink(),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: selectedIndex,
          onTap: onNavTap,
          selectedItemColor: AppColors.iconColor,
          unselectedItemColor: Colors.grey[600],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: List.generate(bottomNavIcons.length, (index) {
            Widget icon = bottomNavIcons[index];

            // Tambahkan badge angka hanya di Konsultasi (index 4) jika nilainya > 0
            if (index == 4 && consultationBadgeCount > 0) {
              icon = Stack(
                clipBehavior: Clip.none,
                children: [
                  icon,
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.buttonBackground,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          consultationBadgeCount > 99
                              ? '99+'
                              : '$consultationBadgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return BottomNavigationBarItem(
              icon: icon,
              label: bottomNavLabels[index],
            );
          }),
        ),
      ),
    );
  }
}
