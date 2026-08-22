// chat_ai_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatAIPage extends StatefulWidget {
  final String sessionKey;

  const ChatAIPage({super.key, required this.sessionKey});

  @override
  State<ChatAIPage> createState() => _ChatAIPageState();
}

class _ChatAIPageState extends State<ChatAIPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentSessionId;
  List<ChatSession> _chatSessions = [];
  bool _showSessionList = false;

  // --- Theme Colors (Glowing Silver) ---
  static const Color primaryColor = Color(0xFFE0E0E0); // Silver/Abu-abu Menyala
  static const Color backgroundColor = Color(0xFF050505); // Hitam Pekat
  static const Color cardColor = Color(0xFF1A1A1A); // Abu-abu Gelap
  static const Color accentColor = Color(0xFFFFFFFF); // Putih untuk highlight

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  Future<void> _loadChatSessions() async {
    try {
      final response = await http.get(Uri.parse('http://hannmodzzprivate.mysrv.web.id:2893/api/tools/chat/list?key=${widget.sessionKey}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _chatSessions = (data['chatHistoryList'] as List).map((session) => ChatSession.fromJson(session)).toList();
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to load chat sessions', isError: true);
    }
  }

  Future<void> _createNewSession() async {
    try {
      final response = await http.get(Uri.parse('http://hannmodzzprivate.mysrv.web.id:2893/api/tools/chat/new-session?key=${widget.sessionKey}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentSessionId = data['sessionId'];
            _messages.clear();
            _showSessionList = false;
          });
          _loadChatSessions();
          _showSnackBar('New session created');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to create new session', isError: true);
    }
  }

  Future<void> _loadChatSession(String sessionId) async {
    try {
      final response = await http.get(Uri.parse('http://hannmodzzprivate.mysrv.web.id:2893/api/tools/chat/history?key=${widget.sessionKey}&session=$sessionId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentSessionId = sessionId;
            _messages.clear();
            final chatHistory = data['chatHistory'] as List;
            for (var message in chatHistory) {
              _messages.add(ChatMessage(
                  text: message['message'],
                  isAI: message['isAI'] == true,
                  timestamp: DateTime.parse(message['timestamp'])
              ));
            }
            _showSessionList = false;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to load chat session', isError: true);
    }
  }

  Future<void> _deleteChatSession(String sessionId) async {
    try {
      final response = await http.get(Uri.parse('http://hannmodzzprivate.mysrv.web.id:2893/api/tools/chat/delete?key=${widget.sessionKey}&session=$sessionId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          _showSnackBar('Chat session deleted');
          _loadChatSessions();
          if (_currentSessionId == sessionId) {
            setState(() {
              _currentSessionId = null;
              _messages.clear();
            });
          }
        }
      }
    } catch (e) {
      _showSnackBar('Failed to delete chat session', isError: true);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _currentSessionId == null) return;
    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isAI: false, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _messageController.clear();
    try {
      final response = await http.get(Uri.parse('http://hannmodzzprivate.mysrv.web.id:2893/api/tools/chat/send?key=${widget.sessionKey}&session=$_currentSessionId&message=${Uri.encodeComponent(userMessage)}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data['status']);
        if (data['status'] == true) {
          setState(() {
            _messages.add(ChatMessage(text: data['data']['message'], isAI: true, timestamp: DateTime.now()));
          });
        } else {
          _showSnackBar('Failed to get AI response', isError: true);
        }
      } else {
        _showSnackBar('Failed to connect to AI service', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? Colors.red.shade900 : cardColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
            'Chat AI', 
            style: TextStyle(
                color: primaryColor, 
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: primaryColor, blurRadius: 5)]
            )
        ),
        iconTheme: const IconThemeData(color: primaryColor),
        actions: [
          IconButton(
              icon: const Icon(Icons.history, color: primaryColor), 
              onPressed: () => setState(() => _showSessionList = !_showSessionList)
          ),
          IconButton(
              icon: const Icon(Icons.add, color: primaryColor), 
              onPressed: _createNewSession
          ),
        ],
      ),
      body: _showSessionList ? _buildSessionList() : _buildChatInterface(),
    );
  }

  Widget _buildSessionList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF222222)))
          ),
          child: Row(
            children: [
              const Text('Chat Sessions', style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                  onPressed: _createNewSession, 
                  child: const Text('New Session', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ),
        Expanded(
          child: _chatSessions.isEmpty
              ? const Center(child: Text('No chat sessions found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            itemCount: _chatSessions.length,
            itemBuilder: (context, index) {
              final session = _chatSessions[index];
              return Container(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF111111)))
                ),
                child: ListTile(
                  title: Text(session.sessionId, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
                  subtitle: Text('${session.messageCount} messages', style: TextStyle(color: primaryColor.withOpacity(0.5))),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteChatSession(session.sessionId)),
                  onTap: () => _loadChatSession(session.sessionId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: _currentSessionId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: primaryColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('Start a new conversation', style: TextStyle(color: primaryColor.withOpacity(0.5))),
                    ],
                  )
                )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
          ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2)),
              const SizedBox(width: 12),
              Text('AI is thinking...', style: TextStyle(color: primaryColor.withOpacity(0.7))),
            ]),
          ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: !message.isAI ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isAI) ...[
            Container(
                padding: const EdgeInsets.all(8), 
                decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle), 
                child: const Icon(Icons.smart_toy, color: Colors.black, size: 16)
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !message.isAI ? primaryColor : cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: !message.isAI ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: !message.isAI ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: message.isAI ? Border.all(color: primaryColor.withOpacity(0.1)) : null,
              ),
              child: Text(
                  message.text, 
                  style: TextStyle(
                      color: !message.isAI ? Colors.black : primaryColor,
                      fontWeight: !message.isAI ? FontWeight.w500 : FontWeight.normal
                  )
              ),
            ),
          ),
          if (!message.isAI) ...[
            const SizedBox(width: 8),
            Container(
                padding: const EdgeInsets.all(8), 
                decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle), 
                child: const Icon(Icons.person, color: Colors.black, size: 16)
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor, 
          border: Border(top: BorderSide(color: primaryColor.withOpacity(0.1), width: 1))
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: primaryColor),
              cursorColor: primaryColor,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: primaryColor.withOpacity(0.3)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.3))
                ),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.3))
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: primaryColor)
                ),
                filled: true,
                fillColor: backgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
            child: IconButton(
                icon: const Icon(Icons.send, color: Colors.black), 
                onPressed: _isLoading ? null : _sendMessage
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isAI; 
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isAI, required this.timestamp});
}

class ChatSession {
  final String sessionId;
  final String username;
  final DateTime lastModified;
  final int messageCount;
  final String preview;
  ChatSession({required this.sessionId, required this.username, required this.lastModified, required this.messageCount, required this.preview});
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId'],
      username: json['username'],
      lastModified: DateTime.parse(json['lastModified']),
      messageCount: json['messageCount'],
      preview: json['preview'],
    );
  }
}