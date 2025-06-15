import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';

class EdukasiPage extends StatefulWidget {
  const EdukasiPage({Key? key}) : super(key: key); // Added Key? key

  @override
  State<EdukasiPage> createState() => _EdukasiPageState();
}

class _EdukasiPageState extends State<EdukasiPage> {
  final List<bool> _isHoveringHorizontal = List.generate(
    _articles.length,
    (index) => false,
  );
  final List<bool> _isHoveringVertical = List.generate(
    _articles.length,
    (index) => false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Wrap with Scaffold
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
                      'Edukasi',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Artikel Pilihan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _articles.length,
                itemBuilder: (context, index) {
                  final article = _articles[index];
                  return MouseRegion(
                    onEnter: (event) => _onEnteredHorizontal(true, index),
                    onExit: (event) => _onEnteredHorizontal(false, index),
                    child: SizedBox(
                      width: 150,
                      child: Card(
                        color: _isHoveringHorizontal[index]
                            ? AppColors.inputFill
                            : AppColors.background,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailEdukasiPage(article: article),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    article.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    article.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.start,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Semua Artikel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: _articles.map((item) {
                final index = _articles.indexOf(item);
                return MouseRegion(
                  onEnter: (event) => _onEnteredVertical(true, index),
                  onExit: (event) => _onEnteredVertical(false, index),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailEdukasiPage(article: item),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isHoveringVertical[index]
                            ? AppColors.inputFill
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${item.author} • ${item.postedOn}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              item.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _onEnteredHorizontal(bool isHovering, int index) {
    setState(() {
      _isHoveringHorizontal[index] = isHovering;
    });
  }

  void _onEnteredVertical(bool isHovering, int index) {
    setState(() {
      _isHoveringVertical[index] = isHovering;
    });
  }
}

class Article {
  final String title;
  final String imageUrl;
  final String author;
  final String postedOn;
  final String content;

  Article({
    required this.title,
    required this.imageUrl,
    this.author = 'Unknown Author',
    this.postedOn = 'Unknown Date',
    this.content =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  });
}

class DetailEdukasiPage extends StatelessWidget {
  final Article article;

  const DetailEdukasiPage({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(article.title),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              article.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
            const SizedBox(height: 16),
            Text(
              article.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${article.author} • ${article.postedOn}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(article.content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

final List<Article> _articles = [
  Article(
    title: "Instagram quietly limits ‘daily time limit’ option",
    author: "MacRumors",
    imageUrl: "https://picsum.photos/id/1000/960/540",
    postedOn: "Yesterday",
    content:
        "Instagram is testing a new feature that allows users to set daily time limits for their usage. This feature is currently being tested with a small group of users.",
  ),
  Article(
    title: "Google Search dark theme goes fully black for some on the web",
    imageUrl: "https://picsum.photos/id/1010/960/540",
    author: "9to5Google",
    postedOn: "4 hours ago",
    content:
        "Google is rolling out a new dark theme for its search results page on the web. The new dark theme is fully black, which should be easier on the eyes in low-light conditions.",
  ),
  Article(
    title: "Judul Artikel Panjang Sekali Melebihi Batas",
    imageUrl: "https://picsum.photos/id/1020/960/540",
    author: "Tech News",
    postedOn: "2 days ago",
    content:
        "This is a longer article to test how the layout handles longer titles and content. We want to make sure everything looks good no matter how much text there is.",
  ),
  Article(
    title: "Artikel Kelima",
    imageUrl: "https://picsum.photos/id/1040/960/540",
    author: "Mobile World",
    postedOn: "3 weeks ago",
    content:
        "The fifth article in our series explores the latest trends in mobile technology. From foldable phones to 5G connectivity, we cover it all.",
  ),
];
