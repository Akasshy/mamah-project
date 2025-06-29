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

    if (_editingMessageId != null) {
      final index = _messages.indexWhere((m) => m['id'] == _editingMessageId);
      if (index != -1) {
        setState(() {
          _messages[index]['message'] = text;
          _messages[index]['updated_at'] = DateTime.now().toIso8601String();
        });
      }
    } else {
      final tempMessage = {
        'id': DateTime.now().millisecondsSinceEpoch, // temporary id
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': null,
        'user': {'id': _userId, 'name': 'Anda'},
      };
      setState(() => _messages.add(tempMessage));
      _scrollToBottom();
    }

    _editingMessageId = null;

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
        await _fetchMessages(); // Sinkronisasi ulang agar data fresh dari server
      }
    } catch (_) {
      // Tidak tampilkan error (karena tidak pakai snackbar)
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

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pesan?'),
        content: const Text('Pesan yang dihapus tidak dapat dikembalikan'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
          ),
        ],
      ),
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

    return Padding(
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
                      Colors.primaries[int.parse(
                            message['user']['id'].toString(),
                          ) %
                          Colors.primaries.length],
                  child: Text(
                    message['user']['name'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ],
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
                          : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                                message['user']['name'],
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white70
                                      : Colors.grey[600],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            Text(
                              timeFormat.format(timestamp),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey[600],
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
              if (isMe) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Colors.primaries[int.parse(_userId.toString()) %
                          Colors.primaries.length],
                  child: Text(
                    'Anda'[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // Text(
                //   '${_messages.length} pesan',
                //   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                // ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
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
                      return _buildMessageBubble(message, isMe);
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
