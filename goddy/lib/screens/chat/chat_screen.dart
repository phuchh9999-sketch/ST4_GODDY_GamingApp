import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend([String? textOverride]) {
    final text = textOverride ?? _messageController.text;
    if (text.trim().isEmpty) return;

    final auth = context.read<AuthService>();
    final chat = context.read<ChatService>();
    final user = auth.currentUser;

    if (user == null) return;

    chat.sendMessage(
      sender: user,
      text: text,
      isSticker: textOverride != null,
    );

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatService>();
    final auth = context.watch<AuthService>();
    final myId = auth.currentUser?.id;
    final myUsername = auth.currentUser?.username;
    final messages = chat.messages;

    if (messages.length != _prevMessageCount) {
      _prevMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: GoddyTheme.bgDark,
      appBar: AppBar(
        title: Text(
          'SẢNH CHAT CỘNG ĐỒNG',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại tin nhắn',
            icon: const Icon(Icons.refresh, color: GoddyTheme.neonCyan),
            onPressed: () => chat.refreshMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message stream
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => chat.refreshMessages(),
              color: GoddyTheme.neonCyan,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  // Kiem tra chinh xac la tin nhan cua minh hay doi phuong
                  final isMe = (myId != null && myId.isNotEmpty && msg.senderId == myId) ||
                      (myUsername != null &&
                          myUsername.isNotEmpty &&
                          msg.senderName.trim().toLowerCase() == myUsername.trim().toLowerCase());

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF1E293B),
                              child: Text(msg.senderAvatar, style: const TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF004D40).withValues(alpha: 0.85) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                border: Border.all(
                                  color: isMe ? GoddyTheme.neonCyan : Colors.white12,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        msg.senderName,
                                        style: const TextStyle(
                                          color: GoddyTheme.neonCyan,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    msg.text,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm').format(msg.timestamp.toLocal()),
                                    style: TextStyle(
                                      color: isMe ? Colors.white60 : GoddyTheme.textMuted,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Quick Sticker / Reaction Chips Bar
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: GoddyTheme.bgDark,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ChatService.quickStickers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final sticker = ChatService.quickStickers[idx];
                return ActionChip(
                  backgroundColor: GoddyTheme.bgCard,
                  side: const BorderSide(color: Colors.white12),
                  label: Text(sticker, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  onPressed: () => _handleSend(sticker),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: GoddyTheme.bgCard,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin vào kênh thế giới...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: GoddyTheme.neonCyan,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.send, size: 18),
                    onPressed: () => _handleSend(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
