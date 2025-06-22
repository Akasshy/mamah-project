import 'package:flutter/material.dart';
import 'package:health_app/ip_config.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:health_app/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class User {
  final String id;
  final String name;
  final Color color;

  User({required this.id, required this.name, required this.color});
}

class Message {
  final int id;
  final String text;
  final User sender;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

class OpenDiskusi extends StatefulWidget {
  final int groupId;
  final String groupName;

  const OpenDiskusi({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<OpenDiskusi> createState() => _OpenDiskusiState();
}

class _OpenDiskusiState extends State<OpenDiskusi> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _userId;
  int? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchMessages();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

  Future<void> _fetchMessages() async {
    if (!mounted) return; // Tambahkan ini
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/groups/${widget.groupId}/messages'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];

      if (!mounted) return; // Tambahkan pengecekan ini juga
      setState(() {
        _messages.clear();
        for (var msg in data) {
          final sender = msg['user'];
          _messages.add(
            Message(
              id: msg['id'],
              text: msg['message'],
              sender: User(
                id: sender['id'].toString(),
                name: sender['name'],
                color:
                    Colors.primaries[int.parse(sender['id'].toString()) %
                        Colors.primaries.length],
              ),
              timestamp: DateTime.parse(msg['created_at']),
            ),
          );
        }
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Gagal ambil pesan: ${response.statusCode}');
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

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

    if (response.statusCode == 201 || response.statusCode == 200) {
      _controller.clear();
      final msgData = json.decode(response.body)['data'];
      final sender = msgData['user'];

      setState(() {
        if (_editingMessageId != null) {
          final index = _messages.indexWhere(
            (msg) => msg.id == _editingMessageId,
          );
          if (index != -1) {
            _messages[index] = Message(
              id: msgData['id'],
              text: msgData['message'],
              sender: User(
                id: sender['id'].toString(),
                name: sender['name'],
                color:
                    Colors.primaries[int.parse(sender['id'].toString()) %
                        Colors.primaries.length],
              ),
              timestamp: DateTime.parse(msgData['created_at']),
            );
          }
        } else {
          _messages.add(
            Message(
              id: msgData['id'],
              text: msgData['message'],
              sender: User(
                id: sender['id'].toString(),
                name: sender['name'],
                color:
                    Colors.primaries[int.parse(sender['id'].toString()) %
                        Colors.primaries.length],
              ),
              timestamp: DateTime.parse(msgData['created_at']),
            ),
          );
        }
        _editingMessageId = null;
      });

      _scrollToBottom();
    } else {
      debugPrint('Gagal kirim pesan: ${response.statusCode}');
    }
  }

  void _showDeleteDialog(int messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Hapus Pesan?'),
        content: const Text('Apakah kamu yakin ingin menghapus pesan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/groups/${widget.groupId}/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _messages.removeWhere((msg) => msg.id == messageId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal menghapus pesan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildAvatar(User user) {
    return CircleAvatar(
      backgroundColor: user.color,
      child: Text(
        user.name[0].toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.inputBorder,
              child: const Icon(Icons.groups, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(widget.groupName, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe =
                          message.sender.id.toString() == _userId.toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                bottom: 4,
                              ),
                              child: Text(
                                isMe ? "Anda" : message.sender.name,
                                style: TextStyle(
                                  color: message.sender.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe) ...[
                                  _buildAvatar(message.sender),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: GestureDetector(
                                    onLongPress: () {
                                      if (isMe) {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (_) => SafeArea(
                                            child: Wrap(
                                              children: [
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.edit,
                                                  ),
                                                  title: const Text(
                                                    'Edit Pesan',
                                                  ),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    setState(() {
                                                      _controller.text =
                                                          message.text;
                                                      _editingMessageId =
                                                          message.id;
                                                    });
                                                  },
                                                ),
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.delete,
                                                  ),
                                                  title: const Text(
                                                    'Hapus Pesan',
                                                  ),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    _showDeleteDialog(
                                                      message.id,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    },

                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? AppColors.buttonBackground
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        message.text,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  _buildAvatar(message.sender),
                                ],
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                top: 4,
                              ),
                              child: Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: AppColors.buttonBackground,
                  ),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

  if (messageDate == today) {
    return 'Hari ini, ${DateFormat('HH:mm').format(timestamp)}';
  } else if (messageDate == yesterday) {
    return 'Kemarin, ${DateFormat('HH:mm').format(timestamp)}';
  } else {
    return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
  }
}
