import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rentals/services/chat_service.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;
  final String itemTitle;
  final String itemImage;

  const ChatRoomPage({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    required this.itemTitle,
    required this.itemImage,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<DatabaseEvent>? _addedSub;
  StreamSubscription<DatabaseEvent>? _changedSub;
  StreamSubscription<DatabaseEvent>? _removedSub;

  List<Map<String, dynamic>> _messages = [];

  Timer? _typingTimer;
  bool _isLocalTyping = false;

  bool _isSending = false;
  bool _isInitialLoad = true;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _loadInitialMessagesAndListen();
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty) {
      if (!_isLocalTyping) {
        _isLocalTyping = true;
        ChatService.setTypingStatus(widget.chatRoomId, true);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _isLocalTyping = false;
        ChatService.setTypingStatus(widget.chatRoomId, false);
      });
    } else {
      if (_isLocalTyping) {
        _isLocalTyping = false;
        ChatService.setTypingStatus(widget.chatRoomId, false);
        _typingTimer?.cancel();
      }
    }
  }

  Future<void> _loadInitialMessagesAndListen() async {
    try {
      final query = ChatService.getMessagesQuery(widget.chatRoomId);

      // 1. Initial one-time load
      final snapshot = await query.get();
      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> map =
            snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> initialList = [];

        map.forEach((key, value) {
          if (value is Map) {
            try {
              final msg = Map<String, dynamic>.from(value);
              msg['key'] = key.toString();
              initialList.add(msg);
            } catch (_) {
              // Silently ignore malformed nodes
            }
          }
        });

        _messages = initialList;
        _sortMessages();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _errorMessage = '';
        });
        _scrollToBottom(instant: true);
      }

      // 2. Incremental listeners
      _addedSub = query.onChildAdded.listen(
        (event) {
          final key = event.snapshot.key;
          final val = event.snapshot.value;
          if (key != null && val is Map) {
            try {
              final msg = Map<String, dynamic>.from(val);
              msg['key'] = key;

              if (mounted) {
                setState(() {
                  final exists = _messages.any((m) => m['key'] == key);
                  if (!exists) {
                    _messages.add(msg);
                    _sortMessages();
                  }
                });
                _scrollToBottom(instant: false);
              }
            } catch (_) {}
          }
        },
        onError: (e, st) {
          debugPrint('Error onChildAdded: $e\n$st');
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = e.toString();
            });
          }
        },
      );

      _changedSub = query.onChildChanged.listen(
        (event) {
          final key = event.snapshot.key;
          final val = event.snapshot.value;
          if (key != null && val is Map) {
            try {
              final msg = Map<String, dynamic>.from(val);
              msg['key'] = key;

              if (mounted) {
                setState(() {
                  final index = _messages.indexWhere((m) => m['key'] == key);
                  if (index != -1) {
                    _messages[index] = msg;
                    _sortMessages();
                  }
                });
              }
            } catch (_) {}
          }
        },
        onError: (e, st) {
          debugPrint('Error onChildChanged: $e\n$st');
        },
      );

      _removedSub = query.onChildRemoved.listen(
        (event) {
          final key = event.snapshot.key;
          if (key != null) {
            if (mounted) {
              setState(() {
                _messages.removeWhere((m) => m['key'] == key);
              });
            }
          }
        },
        onError: (e, st) {
          debugPrint('Error onChildRemoved: $e\n$st');
        },
      );
    } catch (e, st) {
      debugPrint('Error loading initial messages: $e\n$st');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      int timeA = 0;
      if (a['timestamp'] is num) {
        timeA = (a['timestamp'] as num).toInt();
      }
      int timeB = 0;
      if (b['timestamp'] is num) {
        timeB = (b['timestamp'] as num).toInt();
      }
      return timeA.compareTo(timeB);
    });
  }

  void _scrollToBottom({required bool instant}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;

        if (instant || _isInitialLoad) {
          _scrollController.jumpTo(maxScroll);
          _isInitialLoad = false;
        } else {
          // Smooth scroll only if user is already near the bottom
          if (maxScroll > currentScroll && (maxScroll - currentScroll) <= 300) {
            _scrollController.animateTo(
              maxScroll,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    });
  }

  /// Formats a Realtime Database timestamp (milliseconds since epoch) into a readable HH:MM format
  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return '';
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formats the last seen status for the app bar
  String _formatLastSeen(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return 'Offline';
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Last seen $hour:$minute';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Last seen yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Last seen ${date.day} ${months[date.month - 1]}';
  }

  /// Sends a message using the ChatService
  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await ChatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        text: text,
        receiverId: widget.otherUserId,
      );

      // Clear controller and typing status after successful send
      _messageController.clear();
      _isLocalTyping = false;
      ChatService.setTypingStatus(widget.chatRoomId, false);
      _typingTimer?.cancel();

      // Ensure smooth scroll downwards if we originated the message
      _scrollToBottom(instant: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _isLocalTyping = false;
    ChatService.setTypingStatus(widget.chatRoomId, false);
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);

    _addedSub?.cancel();
    _changedSub?.cancel();
    _removedSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF113F67),
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Other User Image
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              backgroundImage: widget.otherUserImage.isNotEmpty
                  ? NetworkImage(widget.otherUserImage)
                  : null,
              child: widget.otherUserImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // Names & Item Title & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName
                        : 'Unknown User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  StreamBuilder<DatabaseEvent>(
                    stream: ChatService.getTypingStatusStream(
                      widget.chatRoomId,
                      widget.otherUserId,
                    ),
                    builder: (context, typingSnapshot) {
                      bool isTyping = false;
                      if (typingSnapshot.hasData &&
                          typingSnapshot.data!.snapshot.value != null) {
                        final data = typingSnapshot.data!.snapshot.value;
                        if (data is Map) {
                          isTyping = data['isTyping'] == true;
                        }
                      }

                      final String itemDisplay = widget.itemTitle.isNotEmpty
                          ? widget.itemTitle
                          : 'Item Inquiry';

                      if (isTyping) {
                        return Row(
                          children: [
                            Flexible(
                              child: Text(
                                itemDisplay,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const Flexible(
                              child: Text(
                                'Typing...',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }

                      return StreamBuilder<DatabaseEvent>(
                        stream: ChatService.getUserStatusStream(
                          widget.otherUserId,
                        ),
                        builder: (context, snapshot) {
                          String statusText = 'Offline';
                          bool isOnline = false;

                          if (snapshot.hasData &&
                              snapshot.data!.snapshot.value != null) {
                            final data = snapshot.data!.snapshot.value;
                            if (data is Map) {
                              isOnline = data['isOnline'] == true;
                              if (isOnline) {
                                statusText = 'Online';
                              } else {
                                int? lastSeen;
                                if (data['lastSeen'] is num) {
                                  lastSeen = (data['lastSeen'] as num).toInt();
                                }
                                statusText = _formatLastSeen(lastSeen);
                              }
                            }
                          }

                          return Row(
                            children: [
                              Flexible(
                                child: Text(
                                  itemDisplay,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: isOnline
                                        ? Colors.greenAccent
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: isOnline
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Item Image Thumbnail
          if (widget.itemImage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  widget.itemImage,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40,
                    height: 40,
                    color: Colors.white24,
                    child: const Icon(
                      Icons.image,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(child: _buildMessagesArea()),

          // Bottom Input Area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF113F67)),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Error loading messages.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet.\nStart the conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final data = _messages[index];
        final String senderId = data['senderId']?.toString() ?? '';
        final String text = data['text']?.toString() ?? '';

        int? timestamp;
        if (data['timestamp'] is num) {
          timestamp = (data['timestamp'] as num).toInt();
        }

        final bool isMe = senderId == widget.currentUserId;

        return _buildMessageBubble(
          text: text,
          timeString: _formatTime(timestamp),
          isMe: isMe,
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required String timeString,
    required bool isMe,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.otherUserImage.isNotEmpty
                  ? NetworkImage(widget.otherUserImage)
                  : null,
              child: widget.otherUserImage.isEmpty
                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF113F67) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
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
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF16BCE6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
