import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Halaman Detail Edukasi
class EducationDetailPage extends StatefulWidget {
  final int id; // ID edukasi yang akan ditampilkan
  const EducationDetailPage({super.key, required this.id});

  @override
  State<EducationDetailPage> createState() => _EducationDetailPageState();
}

class _EducationDetailPageState extends State<EducationDetailPage> {
  Map<String, dynamic>? detail; // Menyimpan data detail edukasi
  YoutubePlayerController? _youtubeController; // Controller video YouTube
  Uint8List? imageBytes; // Byte data untuk gambar
  bool showWebView = false; // Fallback jika load gambar gagal / 403

  @override
  void initState() {
    super.initState();
    fetchDetail(); // Ambil data edukasi saat halaman pertama kali dibuka
  }

  @override
  void dispose() {
    _youtubeController
        ?.dispose(); // Hentikan controller video saat halaman di-close
    super.dispose();
  }

  /// Ambil token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Fetch detail edukasi dari API
  Future<void> fetchDetail() async {
    final token = await _getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final res = await http.get(
      Uri.parse('$baseUrl/api/education/${widget.id}/show'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      if (!mounted) return;

      setState(() => detail = jsonData['data']); // Simpan data detail
      _setupMedia(); // Setup media (video)

      // Jika media berupa gambar, load gambar dengan header
      if ((detail!['media_type'] ?? '').toLowerCase() == 'image') {
        _loadImage(detail!['file_url'] ?? '');
      }
    } else {
      throw Exception('Gagal memuat detail (${res.statusCode})');
    }
  }

  /// Setup media untuk video YouTube
  void _setupMedia() {
    if (detail == null) return;

    final url = detail!['file_url'] ?? '';
    final type = (detail!['media_type'] ?? '').toLowerCase();

    if (type == 'video' &&
        (url.contains('youtube.com') || url.contains('youtu.be'))) {
      final id = YoutubePlayer.convertUrlToId(url);
      if (id != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: id,
          flags: const YoutubePlayerFlags(autoPlay: false),
        );
      }
    }
  }

  /// Load gambar dari network dengan header (fallback WebView jika 403)
  Future<void> _loadImage(String url) async {
    try {
      final uri = Uri.parse(url);
      final referer = baseUrl.replaceAll(RegExp(r'/$'), '');
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'Mozilla/5.0', 'Referer': referer},
      );

      if (res.statusCode == 200) {
        setState(() {
          imageBytes = res.bodyBytes;
          showWebView = false;
        });
      } else if (res.statusCode == 403) {
        setState(() => showWebView = true);
        print('Gambar diblokir, fallback ke WebView');
      } else {
        print('Gagal load gambar: ${res.statusCode}');
      }
    } catch (e) {
      print('Error load gambar: $e');
      setState(() => showWebView = true);
    }
  }

  /// Widget untuk menampilkan media (gambar/video/WebView)
  Widget mediaWidget() {
    if (detail == null) return Container();

    final type = (detail!['media_type'] ?? '').toLowerCase();
    final url = detail!['file_url'] ?? '';

    Widget mediaContent;

    if (type == 'image') {
      // Jika gambar berhasil di-load
      if (imageBytes != null) {
        mediaContent = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Image.memory(
                imageBytes!,
                width: constraints.maxWidth,
                fit: BoxFit.fitWidth, // Sesuaikan lebar, tinggi proporsional
              );
            },
          ),
        );
      }
      // Jika harus fallback ke WebView
      else if (showWebView) {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(url));

        mediaContent = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WebView
              SizedBox(
                height: 300,
                child: WebViewWidget(controller: controller),
              ),
              // Keterangan untuk user
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.05),
                child: const Text(
                  'Geser atau cubit untuk memperbesar/memperkecil gambar.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        );
      }
      // Placeholder loading
      else {
        mediaContent = Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
    }
    // Jika media berupa video
    else if (type == 'video' && _youtubeController != null) {
      mediaContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: true,
            ),
            builder: (context, player) => player,
          ),
        ),
      );
    }
    // Media tidak tersedia
    else {
      mediaContent = Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Media tidak tersedia')),
      );
    }

    // Bungkus media dengan Card agar lebih rapi
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: mediaContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (detail == null) {
      // Tampilkan loading saat data belum tersedia
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(detail!['title'] ?? 'Detail Edukasi'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mediaWidget(), // Tampilkan media
            const SizedBox(height: 8),
            Text(
              detail!['description'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
