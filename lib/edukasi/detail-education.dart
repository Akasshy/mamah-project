import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class EducationDetailPage extends StatefulWidget {
  final int id;
  const EducationDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  State<EducationDetailPage> createState() => _EducationDetailPageState();
}

class _EducationDetailPageState extends State<EducationDetailPage> {
  Map<String, dynamic>? detail;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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
      setState(() => detail = jsonData['data']);
      _setupMedia();
    } else {
      throw Exception('Gagal memuat detail (${res.statusCode})');
    }
  }

  void _setupMedia() {
    if (detail == null) return;
    final type = (detail!['media_type'] ?? '').toLowerCase();
    final url = (detail!['file_url'] ?? '') as String;

    if (type == 'video') {
      // 1. Jika YouTube
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        final id = YoutubePlayer.convertUrlToId(url);
        if (id != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: id,
            flags: const YoutubePlayerFlags(autoPlay: false),
          );
        }
      }
      // 2. Jika file mp4 atau link drive
      else if (url.endsWith('.mp4')) {
        _videoController = VideoPlayerController.network(url)
          ..initialize().then((_) => setState(() {}));
      } else if (url.contains('drive.google.com')) {
        final reg = RegExp(r'/d/([a-zA-Z0-9_-]+)');
        final match = reg.firstMatch(url);
        if (match != null) {
          final direct =
              'https://drive.google.com/uc?export=download&id=${match.group(1)}';
          _videoController = VideoPlayerController.network(direct)
            ..initialize().then((_) => setState(() {}));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final type = (detail!['media_type'] ?? '').toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(detail!['title'] ?? 'Detail Edukasi'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'image')
              Image.network(detail!['file_url'])
            else if (type == 'video')
              _youtubeController != null
                  ? AspectRatio(
                      aspectRatio: 16 / 9,
                      child: YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                      ),
                    )
                  : (_videoController != null &&
                        _videoController!.value.isInitialized)
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: Text('Video tidak tersedia')),
                    )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Text('Media tidak tersedia')),
              ),
            const SizedBox(height: 16),
            Text(
              detail!['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
