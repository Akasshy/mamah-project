import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/profile.dart';

class Beranda extends StatelessWidget {
  const Beranda({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls = [
      'images/baner.jpg',
      'images/baner2.jpeg',
      'images/baner.jpg',
      'images/baner2.jpeg',
      'images/baner.jpg',
    ];

    return Scaffold(
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
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Image.asset(
                          'images/logo.png',
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Akasshy',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(),
                              ),
                            );
                          },
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=3',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.width * 6 / 16,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      margin: const EdgeInsets.only(right: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, exception, stackTrace) {
                            return const Center(
                              child: Text('Failed to load image'),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                'Ringkasan Skor Skrining Terakhir',
                'Skor Anda: 12',
                Colors.green[100],
                Icons.check_circle,
              ),
              const SizedBox(height: 16),
              _buildNotificationCard(
                'Notifikasi',
                'Anda memiliki 2 notifikasi baru.',
                Colors.blue[100],
                Icons.notifications_active,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Informasi Terbaru',
                'Jangan lupa untuk melakukan skrining kesehatan mental Anda.',
                Colors.orange[100],
                Icons.info_outline,
              ),
              const SizedBox(height: 16),
              _buildTipsCard(
                'Tips Kesehatan Ibu Setelah Melahirkan',
                '1. Istirahat yang cukup.\n2. Makan makanan bergizi.\n3. Jaga kesehatan mental.',
                Colors.pink[100],
                Icons.favorite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
    return _buildCardTemplate(title, content, color, icon);
  }

  Widget _buildNotificationCard(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
    return _buildCardTemplate(title, content, color, icon);
  }

  Widget _buildInfoCard(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
    return _buildCardTemplate(title, content, color, icon);
  }

  Widget _buildTipsCard(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
    return _buildCardTemplate(title, content, color, icon);
  }

  Widget _buildCardTemplate(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color ?? Colors.grey.shade200, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: Colors.black54),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(content, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
