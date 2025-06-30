import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ibu/skrining/question_page.dart';
import 'package:health_app/ibu/skrining/show_score_page.dart';

class SkriningsPage extends StatelessWidget {
  const SkriningsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Skrining Kesehatan Ibu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.black54),
              onPressed: () {
                _showInfoDialog(context);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Layanan Skrining',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih jenis skrining yang ingin Anda lakukan:',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ...menuItems
                  .map(
                    (item) => _ModernMenuCard(
                      title: item.title,
                      icon: item.icon,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => item.page),
                        );
                      },
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentang Skrining',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Skrining ini membantu mendeteksi dini kondisi kesehatan mental ibu. '
                'Hasilnya akan memberikan gambaran tentang kondisi Anda saat ini.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModernMenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModernMenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ModernMenuCard> createState() => _ModernMenuCardState();
}

class _ModernMenuCardState extends State<_ModernMenuCard> {
  bool _isHovered = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isTapped = true),
        onTapUp: (_) => setState(() => _isTapped = false),
        onTapCancel: () => setState(() => _isTapped = false),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: _isTapped
                  ? AppColors.inputBorderFocused.withOpacity(0.1)
                  : _isHovered
                  ? AppColors.inputFill
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
              border: Border.all(
                color: _isHovered
                    ? AppColors.inputBorderFocused.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBorderFocused.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    widget.icon,
                    color: AppColors.inputBorderFocused,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSubtitle(widget.title),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSubtitle(String title) {
    switch (title) {
      case 'Isi Kuesioner EPDS':
        return 'Skrining kesehatan mental ibu';
      case 'Hasil Skrining':
        return 'Lihat riwayat hasil skrining';
      default:
        return 'Layanan skrining kesehatan';
    }
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
    title: 'Hasil Skrining',
    icon: Icons.bar_chart_rounded,
    page: const LihatSkor(),
  ),
];
