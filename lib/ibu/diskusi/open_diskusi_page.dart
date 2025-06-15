import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:health_app/app_colors.dart';

class User {
  final String id;
  final String name;
  final Color color;

  User({required this.id, required this.name, required this.color});
}

class Message {
  final String text;
  final User sender;
  final DateTime timestamp;

  Message({required this.text, required this.sender, required this.timestamp});
}

class ChatService {
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<Set<User>> _typingController =
      StreamController<Set<User>>.broadcast();
  final Random _random = Random();

  final List<User> users = [
    User(id: '1', name: 'You', color: Colors.blue),
    User(id: '2', name: 'Alice', color: Colors.purple),
    User(id: '3', name: 'Bob', color: Colors.green),
    User(id: '4', name: 'Charlie', color: Colors.orange),
  ];

  User get currentUser => users[0];
  Stream<Message> get messageStream => _messageController.stream;
  Stream<Set<User>> get typingStream => _typingController.stream;

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final message = Message(
      text: text,
      sender: currentUser,
      timestamp: DateTime.now(),
    );

    _messageController.add(message);
    _simulateResponses(text);
  }

  void _simulateResponses(String originalMessage) {
    final numResponses = _random.nextInt(3) + 1;
    final typingUsers = <User>{};

    for (var i = 0; i < numResponses; i++) {
      final delay = _random.nextInt(3) + 1;
      final randomUser = users[_random.nextInt(users.length - 1) + 1];
      typingUsers.add(randomUser);
      _typingController.add(Set.from(typingUsers));

      Future.delayed(Duration(seconds: delay), () {
        typingUsers.remove(randomUser);
        _typingController.add(Set.from(typingUsers));

        final response = Message(
          text: "${randomUser.name} responds to: $originalMessage",
          sender: randomUser,
          timestamp: DateTime.now(),
        );

        _messageController.add(response);
      });
    }
  }

  void dispose() {
    _messageController.close();
    _typingController.close();
  }
}

class OpenDiskusi extends StatefulWidget {
  const OpenDiskusi({super.key});

  @override
  State<OpenDiskusi> createState() => _OpenDiskusiState();
}

class _OpenDiskusiState extends State<OpenDiskusi> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<Message> _messages = [];
  Set<User> _typingUsers = {};
  bool _isJoined = false; // Status bergabung

  @override
  void initState() {
    super.initState();
    _chatService.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    });

    _chatService.typingStream.listen((users) {
      setState(() {
        _typingUsers = users;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    _chatService.sendMessage(text);
    _controller.clear();
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(User user) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          _buildAvatar(user),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
                  child: _buildDot(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      curve: Interval(index * 0.2, (index + 1) * 0.2, curve: Curves.easeInOut),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -2 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  void _joinGroup() {
    setState(() {
      _isJoined = true; // Set status bergabung menjadi true
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              color: Colors.white,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailDiskusi(),
                  ),
                );
              },
              child: Row(
                children: [
                  Hero(
                    tag: 'group-icon',
                    child: CircleAvatar(
                      backgroundColor: AppColors.inputBorder,
                      child: const Icon(Icons.groups, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hamil tidak sengaja',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + _typingUsers.length,
                itemBuilder: (context, index) {
                  if (index >= _messages.length) {
                    final typingUser = _typingUsers.elementAt(
                      index - _messages.length,
                    );
                    return _buildTypingIndicator(typingUser);
                  }

                  final message = _messages[index];
                  final isMe = message.sender.id == _chatService.currentUser.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          _buildAvatar(message.sender),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    message.sender.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 8),
                          _buildAvatar(message.sender),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (!_isJoined) // Tampilkan tombol bergabung jika belum bergabung
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity, // Lebar penuh
                  child: ElevatedButton(
                    onPressed: _joinGroup,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: AppColors
                          .buttonBackground, // Warna latar belakang hijau
                    ),
                    child: const Text(
                      'Bergabung ke Grup',
                      style: TextStyle(color: Colors.white), // Teks putih
                    ),
                  ),
                ),
              ),
            if (_isJoined) // Tampilkan input field jika sudah bergabung
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
                        decoration: const InputDecoration(
                          hintText: 'Ketik pesan...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: _sendMessage,
                        style: const TextStyle(color: Colors.black87),
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
      ),
    );
  }
}

// Detail Diskusi
class DetailDiskusi extends StatelessWidget {
  const DetailDiskusi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Grup'),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Ikon grup di tengah
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
            // Nama grup
            const Text(
              'Mapia Sawah',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Deskripsi grup
            const Text(
              'Grup diskusi yang membahas segala hal tentang kehidupan petani sawah secara santai dan mendalam.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.labelText),
            ),
          ],
        ),
      ),
    );
  }
}
