import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OpenKonsultasi extends StatefulWidget {
  final int konsultasiId;

  const OpenKonsultasi({Key? key, required this.konsultasiId})
    : super(key: key);

  @override
  State<OpenKonsultasi> createState() => _OpenKonsultasiState();
}

class _OpenKonsultasiState extends State<OpenKonsultasi> {
  List<Map<String, dynamic>> _chat = [];
  final TextEditingController _controller = TextEditingController();
  String? _userId;
  String? _userRole;
  bool _isSending = false;
  int? _editingReplyId;

  String _lawanBicaraName = '';
  String? _lawanBicaraPhoto;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserInfo();
    await _fetchKonsultasi();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _userRole = prefs.getString('role');
  }

  // Future<void> _fetchKonsultasi() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');

  //   final response = await http.get(
  //     Uri.parse('$baseUrl/api/consultations/${widget.konsultasiId}/show'),
  //     headers: {'Authorization': 'Bearer $token'},
  //   );

  //   if (response.statusCode == 200 && mounted) {
  //     final data = jsonDecode(response.body)['data'];
  //     final List<dynamic> reply = data['reply'] ?? [];

  //     // Ambil ID pembuat topik
  //     String topicOwnerId = _userRole == 'ibu'
  //         ? data['ibu_id'].toString()
  //         : data['bidan_id'].toString();

  //     setState(() {
  //       // Ambil ID pembuat topik berdasarkan role login
  //       final topicOwnerId = _userRole == 'ibu'
  //           ? data['ibu_id'].toString()
  //           : data['bidan_id'].toString();

  //       _chat = [
  //         {
  //           'id': data['id'],
  //           'sender': data['topic'], // atau pakai nama ibu/bidan kalau mau
  //           'message': data['topic'],
  //           'isQuestion': true,
  //           'user_id':
  //               topicOwnerId, // ✅ ID pembuat topik, bukan dari field 'user_id'
  //         },
  //         ...reply.map(
  //           (e) => {
  //             'id': e['id'],
  //             'sender_id': e['sender_id']?.toString(),
  //             'message': e['message'],
  //             'isQuestion': false,
  //             'created_at': e['created_at'],
  //             'updated_at': e['updated_at'],
  //           },
  //         ),
  //       ];

  //       if (_userRole == 'ibu') {
  //         _lawanBicaraName = data['bidan'] ?? '';
  //         _lawanBicaraPhoto = data['bidan_photo'];
  //       } else {
  //         _lawanBicaraName = data['ibu'] ?? '';
  //         _lawanBicaraPhoto = data['ibu_photo'];
  //       }
  //     });
  //   }
  // }
  Future<void> _fetchKonsultasi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/consultations/${widget.konsultasiId}/show'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && mounted) {
      final data = jsonDecode(response.body)['data'];
      final List<dynamic> reply = data['reply'] ?? [];

      setState(() {
        _chat = reply
            .map<Map<String, dynamic>>(
              (e) => {
                'id': e['id'],
                'sender_id': e['sender_id']?.toString(),
                'message': e['message'],
                'isQuestion': false,
                'created_at': e['created_at'],
                'updated_at': e['updated_at'],
              },
            )
            .toList();

        // Set lawan bicara berdasarkan role yang login
        if (_userRole == 'ibu') {
          _lawanBicaraName = data['bidan'] ?? '';
          _lawanBicaraPhoto = data['bidan_photo'];
        } else {
          _lawanBicaraName = data['ibu'] ?? '';
          _lawanBicaraPhoto = data['ibu_photo'];
        }
      });
    }
  }

  Future<void> _sendReply() async {
    if (_controller.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/api/consultations/reply');
    final body = {
      'consultation_id': widget.konsultasiId.toString(),
      'message': _controller.text,
      if (_editingReplyId != null) 'reply_id': _editingReplyId.toString(),
    };

    setState(() => _isSending = true);

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _controller.clear();
      _editingReplyId = null;
      await _fetchKonsultasi();
    }

    setState(() => _isSending = false);
  }

  Future<void> _deleteReply(int replyId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/consultations/reply/$replyId/delete'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      await _fetchKonsultasi();
    }
  }

  void _showMessageOptions(int messageId, String messageText) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Pesan'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _controller.text = messageText;
                  _editingReplyId = messageId;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Pesan'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(messageId);
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(int messageId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Hapus Pesan?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pesan yang dihapus tidak dapat dikembalikan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.black),
                      label: const Text('Batal'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteReply(messageId);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        foregroundColor: AppColors.background,
        backgroundColor: AppColors.buttonBackground,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _lawanBicaraPhoto != null
                  ? NetworkImage(_lawanBicaraPhoto!)
                  : const AssetImage('images/default-pp.jpg') as ImageProvider,
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _lawanBicaraName,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.background,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _chat.length,
              itemBuilder: (context, index) {
                final msg = _chat[index];
                final isMe = msg['isQuestion']
                    ? (msg['user_id']?.toString() == _userId)
                    : (msg['sender_id']?.toString() == _userId);

                return GestureDetector(
                  onLongPress: () {
                    if (!msg['isQuestion'] && isMe) {
                      _showMessageOptions(msg['id'], msg['message']);
                    }
                  },
                  child: Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.buttonBackground
                            : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['message'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!msg['isQuestion'])
                            Text(
                              _formatTimestamp(msg),
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: _editingReplyId != null
                          ? 'Edit pesan...'
                          : 'Ketik pesan...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: _isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendReply,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Map<String, dynamic> msg) {
    final createdAt = msg['created_at'];
    final updatedAt = msg['updated_at'];
    if (createdAt == null) return '';
    final isEdited = updatedAt != null && createdAt != updatedAt;
    final time = isEdited ? updatedAt : createdAt;

    try {
      final dateTime = DateTime.parse(time).toLocal();
      final formatted =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return isEdited ? '$formatted (diedit)' : formatted;
    } catch (_) {
      return '';
    }
  }
}
