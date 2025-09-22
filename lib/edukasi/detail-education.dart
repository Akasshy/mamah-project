import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationDetailPage extends StatefulWidget {
  final int id;
  const EducationDetailPage({super.key, required this.id});

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

  String getValidUrl(String url) {
    if (url.contains('127.0.0.1')) {
      final server = baseUrl.replaceAll(RegExp(r'/$'), '');
      return url.replaceAll('127.0.0.1', server);
    }
    return url;
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

    final url = getValidUrl(detail!['file_url'] ?? '');
    final type = (detail!['media_type'] ?? '').toLowerCase();

    if (type == 'video') {
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        final id = YoutubePlayer.convertUrlToId(url);
        if (id != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: id,
            flags: const YoutubePlayerFlags(autoPlay: false),
          );
        }
      } else if (url.endsWith('.mp4')) {
        _videoController = VideoPlayerController.network(url)
          ..initialize().then((_) => setState(() {}));
      } else if (url.contains('drive.google.com')) {
        final reg = RegExp(r'/d/([a-zA-Z0-9_-]+)');
        final match = reg.firstMatch(url);
        if (match != null) {
          final directUrl =
              'https://drive.google.com/uc?export=download&id=${match.group(1)}';
          _videoController = VideoPlayerController.network(directUrl)
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

  Widget mediaWidget() {
    if (detail == null) return Container();

    final url = getValidUrl(detail!['file_url'] ?? '');
    final type = (detail!['media_type'] ?? '').toLowerCase();

    if (type == 'image') {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: AppColors.inputFill,
          child: const Center(child: Text('Gambar tidak tersedia')),
        ),
      );
    }

    if (type == 'video') {
      // ✅ YOUTUBE
      if (_youtubeController != null) {
        return YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
          ),
          builder: (context, player) => player,
        );
      }

      // ✅ MP4 / DRIVE VIDEO
      if (_videoController != null && _videoController!.value.isInitialized) {
        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () async {
                  await SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeRight,
                    DeviceOrientation.landscapeLeft,
                  ]);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FullScreenVideoPage(controller: _videoController!),
                    ),
                  );
                  await SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown,
                  ]);
                },
              ),
            ),
          ],
        );
      }

      // ✅ Google Drive fallback
      if (url.contains('drive.google.com')) {
        return Container(
          height: 200,
          color: AppColors.inputFill,
          child: Center(
            child: ElevatedButton(
              onPressed: () async {
                final reg = RegExp(r'/d/([a-zA-Z0-9_-]+)');
                final match = reg.firstMatch(url);
                if (match != null) {
                  final directUrl =
                      'https://drive.google.com/uc?export=download&id=${match.group(1)}';
                  if (await canLaunchUrl(Uri.parse(directUrl))) {
                    await launchUrl(Uri.parse(directUrl));
                  }
                }
              },
              child: const Text('Putar Video'),
            ),
          ),
        );
      }

      return Container(
        height: 200,
        color: AppColors.inputFill,
        child: const Center(child: Text('Video tidak tersedia')),
      );
    }

    return Container(
      height: 200,
      color: AppColors.inputFill,

      child: const Center(child: Text('Media tidak tersedia')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(detail!['title'] ?? 'Detail Edukasi'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mediaWidget(),
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

class FullScreenVideoPage extends StatelessWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          Positioned(
            top: 30,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
