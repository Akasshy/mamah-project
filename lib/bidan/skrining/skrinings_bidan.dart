import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Tambahkan ini
import 'package:health_app/app_colors.dart';
import 'package:health_app/bidan/skrining/detail_skrining.dart';
// import 'package:health_app/ibu/konsultasi/open_konsultasi_page.dart';

class SkriningBidan extends StatefulWidget {
  const SkriningBidan({Key? key}) : super(key: key);

  @override
  State<SkriningBidan> createState() => _SkriningBidanState();
}

class _SkriningBidanState extends State<SkriningBidan> {
  final List<Map<String, dynamic>> chats = const [
    {'name': 'Sung Hunter', 'imageUrl': 'images/pp.jpg'},
    {'name': 'Sunda Empire', 'imageUrl': ''},
    {'name': 'Mapia sawah', 'imageUrl': ''},
  ];

  final List<bool> _isHovering = List.generate(3, (index) => false);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredChats = [];

  @override
  void initState() {
    super.initState();
    _filteredChats = chats;
    _searchController.addListener(_filterChats);
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChats = chats.where((chat) {
        final name = chat['name'].toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // status bar transparan
        statusBarIconBrightness: Brightness.dark, // icon status bar hitam
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
                    children: [
                      const Text(
                        'Skrining',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
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
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari hasil skiring.',
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
                padding: const EdgeInsets.symmetric(vertical: 0),
                itemCount: _filteredChats.length,
                itemBuilder: (context, index) {
                  final chat = _filteredChats[index];
                  final String imagePath = chat['imageUrl'];

                  return MouseRegion(
                    onEnter: (event) => _onEntered(true, index),
                    onExit: (event) => _onEntered(false, index),
                    child: ListTile(
                      leading: imagePath.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: AssetImage(imagePath),
                              backgroundColor: Colors.grey[300],
                            )
                          : CircleAvatar(
                              backgroundColor: AppColors.inputBorder,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                      title: Text(
                        chat['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        ),
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
                            builder: (context) => const DetailSkrining(),
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

  void _onEntered(bool isHovering, int index) {
    setState(() {
      _isHovering[index] = isHovering;
    });
  }
}
