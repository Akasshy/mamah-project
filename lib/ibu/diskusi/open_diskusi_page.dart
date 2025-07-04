import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OpenDiskusi extends StatefulWidget {
  final int groupId;
  final String groupName;

  const OpenDiskusi({Key? key, required this.groupId, required this.groupName})
    : super(key: key);

  @override
  State<OpenDiskusi> createState() => _OpenDiskusiState();
}

class _OpenDiskusiState extends State<OpenDiskusi> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  String? _userId;
  int? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _generateColorFromId(String id) {
    final hash = id.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(255, r, g, b).withOpacity(1.0);
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

  Future<void> _fetchMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/groups/${widget.groupId}/messages'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List<dynamic>;
        if (!mounted) return;
        setState(() {
          _messages = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Error fetching message diabaikan
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final text = _controller.text;
    _controller.clear();

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/groups/${widget.groupId}/store'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {
          'message': text,
          if (_editingMessageId != null) 'id': _editingMessageId.toString(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchMessages();
      }

      _editingMessageId = null;
    } catch (_) {
      // Optional: tampilkan error
    }

    setState(() => _isSending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                  _editingMessageId = messageId;
                });
                FocusScope.of(context).requestFocus(FocusNode());
                Future.delayed(Duration.zero, () {
                  FocusScope.of(context).requestFocus(FocusNode());
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
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_forever_rounded,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Pesan?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pesan yang dihapus tidak dapat dipulihkan. Lanjutkan?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMessage(messageId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMessage(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      _messages.removeWhere((msg) => msg['id'] == messageId);
    });

    try {
      await http.delete(
        Uri.parse('$baseUrl/api/groups/${widget.groupId}/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      // Tidak tampilkan pesan sukses atau gagal
    } catch (_) {
      // Tidak tampilkan pesan error
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final timestamp = DateTime.parse(message['created_at']);
    final timeFormat = DateFormat('HH:mm');
    final isEdited =
        message['updated_at'] != null &&
        message['updated_at'] != message['created_at'];
    final userId = message['user']['id'].toString();
    final userName = message['user']['name'];
    final imageUrl = message['user']['image'];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),

      child: Padding(
        key: ValueKey(message['id']),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        imageUrl != null && imageUrl.toString().isNotEmpty
                        ? Colors.transparent
                        : _generateColorFromId(userId),
                    backgroundImage:
                        imageUrl != null && imageUrl.toString().isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl == null || imageUrl.toString().isEmpty)
                        ? Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const SizedBox(
                    width: 40,
                  ), // 🟢 Tambahan agar sejajar dengan bubble orang lain
                ],

                // Bubble pesan
                Flexible(
                  child: GestureDetector(
                    onLongPress: () {
                      if (isMe) {
                        _showMessageOptions(message['id'], message['message']);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.buttonBackground
                            : const Color.fromARGB(255, 207, 255, 208),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['message'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              if (!isMe)
                                Text(
                                  userName,
                                  style: TextStyle(
                                    color: _generateColorFromId(userId),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              Text(
                                timeFormat.format(timestamp),
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white70
                                      : Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              if (isEdited)
                                Text(
                                  '(diedit)',
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.buttonBackground,
        elevation: 1,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailDiskusi(groupId: widget.groupId),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.groupName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada pesan',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _fetchMessages,
                          child: const Text('Muat Ulang'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe =
                          message['user']['id'].toString() ==
                          _userId.toString();

                      // Cek apakah ini pesan pertama atau user sebelumnya beda
                      final isDifferentSender =
                          index == 0 ||
                          _messages[index]['user']['id'] !=
                              _messages[index - 1]['user']['id'];

                      return Column(
                        children: [
                          if (isDifferentSender)
                            const SizedBox(
                              height: 4,
                            ), // tambahkan spasi jika user beda
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailDiskusi extends StatefulWidget {
  final int groupId;

  const DetailDiskusi({super.key, required this.groupId});

  @override
  State<DetailDiskusi> createState() => _DetailDiskusiState();
}

class _DetailDiskusiState extends State<DetailDiskusi> {
  String? groupName;
  String? description;
  String? creatorName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGroupDetail();
  }

  Future<void> fetchGroupDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/groups/${widget.groupId}/show'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          groupName = data['name'];
          description = data['description'] ?? '-';
          creatorName = data['creator']?['name'] ?? '-';
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data grup');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Grup'),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'group-icon',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.iconColor.withOpacity(0.15),
                      child: const Icon(
                        Icons.groups,
                        size: 40,
                        color: AppColors.iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    groupName ?? '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description ?? '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.labelText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Pembuat: $creatorName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
