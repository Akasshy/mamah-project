import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onNavTap;
  final int consultationBadgeCount;

  const CustomScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onNavTap,
    this.consultationBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: selectedIndex,
          onTap: onNavTap,
          selectedItemColor: AppColors.buttonBackground,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: [
            _buildBottomNavItem(Icons.home_outlined, Icons.home, 'Beranda'),
            // _buildBottomNavItem(
            //   Icons.assignment_outlined,
            //   Icons.assignment,
            //   'Skrining',
            // ),
            // _buildBottomNavItem(
            //   Icons.menu_book_outlined,
            //   Icons.menu_book,
            //   'Edukasi',
            // ),
            // _buildBottomNavItem(Icons.forum_outlined, Icons.forum, 'Diskusi'),
            _buildBottomNavItem(
              Icons.chat_outlined,
              Icons.chat,
              'Konsultasi',
              // showBadge: consultationBadgeCount > 0,
              // badgeCount: consultationBadgeCount,
            ),
            _buildBottomNavItem(
              Icons.person_2_outlined,
              Icons.person,
              'Profile',
              // showBadge: consultationBadgeCount > 0,
              // badgeCount: consultationBadgeCount,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
    IconData outlineIcon,
    IconData filledIcon,
    String label, {
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(outlineIcon),
          if (showBadge)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      activeIcon: Icon(filledIcon),
      label: label,
    );
  }
}
