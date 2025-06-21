import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ibu/konsultasi/open_konsultasi_page.dart';

class KonsultasiPage extends StatefulWidget {
  const KonsultasiPage({Key? key}) : super(key: key);

  @override
  State<KonsultasiPage> createState() => _KonsultasiPageState();
}

class _KonsultasiPageState extends State<KonsultasiPage> {
  final List<Map<String, dynamic>> _allChats = const [
    {
      'name': 'Sung Hunter',
      'message': 'hidup joko...',
      'imageUrl': 'images/pp.jpg',
    },
    {'name': 'Sunda Empire', 'message': 'hidupp cahu', 'imageUrl': ''},
    {'name': 'Mapia sawah', 'message': 'hidup blonde', 'imageUrl': ''},
  ];

  List<Map<String, dynamic>> _filteredChats = [];
  final TextEditingController _searchController = TextEditingController();
  final List<bool> _isHovering = [];

  @override
  void initState() {
    super.initState();
    _filteredChats = List.from(_allChats);
    _isHovering.addAll(List.generate(_allChats.length, (_) => false));
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filteredChats = _allChats
          .where(
            (chat) =>
                chat['name'].toLowerCase().contains(keyword) ||
                chat['message'].toLowerCase().contains(keyword),
          )
          .toList();
    });
  }

  void _onEntered(bool isHovering, int index) {
    if (index < _isHovering.length) {
      setState(() {
        _isHovering[index] = isHovering;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Untuk status bar gelap
      ),
      child: Scaffold(
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
                    children: const [
                      Text(
                        'Konsultasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau pesan...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.buttonBackground,
                  ),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorderFocused,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorder,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredChats.length,
                itemBuilder: (context, index) {
                  final chat = _filteredChats[index];
                  final String imagePath = chat['imageUrl'];
                  final String message = chat['message'];

                  return MouseRegion(
                    onEnter: (_) => _onEntered(true, index),
                    onExit: (_) => _onEntered(false, index),
                    child: ListTile(
                      leading: imagePath.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: AssetImage(imagePath),
                              backgroundColor: Colors.grey[300],
                            )
                          : const CircleAvatar(
                              backgroundColor: AppColors.inputBorder,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                      title: Text(
                        chat['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.labelText),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      tileColor: _isHovering[index]
                          ? AppColors.inputFill
                          : AppColors.background,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OpenKonsultasi(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
