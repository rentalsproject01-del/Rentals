import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentals/services/chat_service.dart';
import 'package:rentals/views/chat/widgets/chat_header_status.dart';
import 'package:rentals/views/chat/widgets/chat_message_bubble.dart';
import 'package:rentals/views/chat/widgets/floating_typing_indicator.dart';

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
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  StreamSubscription<DatabaseEvent>? _addedSub;
  StreamSubscription<DatabaseEvent>? _changedSub;
  StreamSubscription<DatabaseEvent>? _removedSub;

  final List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  final Set<String> _readReceiptInFlight = <String>{};
  Timer? _typingTimer;

  bool _isLocalTyping = false;
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
    } else if (_isLocalTyping) {
      _isLocalTyping = false;
      ChatService.setTypingStatus(widget.chatRoomId, false);
      _typingTimer?.cancel();
    }
  }

  Future<void> _loadInitialMessagesAndListen() async {
    try {
      final query = ChatService.getMessagesQuery(widget.chatRoomId);
      final snapshot = await query.get();
      final initialMessages = <Map<String, dynamic>>[];

      if (snapshot.exists && snapshot.value is Map) {
        final map = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in map.entries) {
          if (entry.value is Map) {
            try {
              final msg = Map<String, dynamic>.from(entry.value as Map);
              msg['key'] = entry.key.toString();
              initialMessages.add(msg);
            } catch (_) {}
          }
        }
        initialMessages.sort(
          (a, b) => _timestampOf(a).compareTo(_timestampOf(b)),
        );
        _messages
          ..clear()
          ..addAll(initialMessages);
        unawaited(
          _markMessagesAsReadIfNeeded(
            List<Map<String, dynamic>>.from(_messages),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _errorMessage = '';
        });
        _scrollToBottom(instant: true);
      }

      _addedSub = query.onChildAdded.listen(
        (event) {
          final key = event.snapshot.key;
          final value = event.snapshot.value;
          if (key == null || value is! Map || !mounted) return;

          try {
            final msg = Map<String, dynamic>.from(value);
            msg['key'] = key;
            final alreadyExists = _messages.any(
              (message) => message['key'] == key,
            );
            if (alreadyExists) {
              return;
            }
            setState(() {
              _insertMessageSorted(msg);
            });
            unawaited(_markMessagesAsReadIfNeeded([msg]));
            _scrollToBottom(instant: false);
          } catch (_) {}
        },
        onError: (e, st) {
          debugPrint('Error onChildAdded: $e\n$st');
          if (!mounted) return;
          setState(() {
            _hasError = true;
            _errorMessage = e.toString();
          });
        },
      );

      _changedSub = query.onChildChanged.listen(
        (event) {
          final key = event.snapshot.key;
          final value = event.snapshot.value;
          if (key == null || value is! Map || !mounted) return;

          try {
            final msg = Map<String, dynamic>.from(value);
            msg['key'] = key;
            setState(() {
              _applyChangedMessage(msg);
            });
            unawaited(_markMessagesAsReadIfNeeded([msg]));
          } catch (_) {}
        },
        onError: (e, st) {
          debugPrint('Error onChildChanged: $e\n$st');
        },
      );

      _removedSub = query.onChildRemoved.listen(
        (event) {
          final key = event.snapshot.key;
          if (key == null || !mounted) return;
          setState(() {
            _messages.removeWhere((m) => m['key'] == key);
          });
        },
        onError: (e, st) {
          debugPrint('Error onChildRemoved: $e\n$st');
        },
      );
    } catch (e, st) {
      debugPrint('Error loading initial messages: $e\n$st');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  int _insertIndexForTimestamp(int timestamp) {
    var low = 0;
    var high = _messages.length;

    while (low < high) {
      final mid = (low + high) >> 1;
      if (_timestampOf(_messages[mid]) <= timestamp) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low;
  }

  void _insertMessageSorted(Map<String, dynamic> message) {
    final timestamp = _timestampOf(message);
    if (_messages.isEmpty || _timestampOf(_messages.last) <= timestamp) {
      _messages.add(message);
      return;
    }

    _messages.insert(_insertIndexForTimestamp(timestamp), message);
  }

  void _applyChangedMessage(Map<String, dynamic> message) {
    final key = message['key']?.toString() ?? '';
    if (key.isEmpty) {
      return;
    }

    final existingIndex = _messages.indexWhere((data) => data['key'] == key);
    if (existingIndex == -1) {
      _insertMessageSorted(message);
      return;
    }

    final existingTimestamp = _timestampOf(_messages[existingIndex]);
    final updatedTimestamp = _timestampOf(message);

    if (existingTimestamp == updatedTimestamp) {
      _messages[existingIndex] = message;
      return;
    }

    _messages.removeAt(existingIndex);
    _messages.insert(_insertIndexForTimestamp(updatedTimestamp), message);
  }

  int _timestampOf(Map<String, dynamic> data) {
    if (data['timestamp'] is num) {
      return (data['timestamp'] as num).toInt();
    }
    return 0;
  }

  bool _shouldMarkAsRead(Map<String, dynamic> data) {
    final key = data['key']?.toString() ?? '';
    if (key.isEmpty || _readReceiptInFlight.contains(key)) {
      return false;
    }

    return ChatService.shouldMarkMessageAsRead(
      messageData: data,
      currentUserId: widget.currentUserId,
      otherUserId: widget.otherUserId,
    );
  }

  Future<void> _markMessagesAsReadIfNeeded(
    Iterable<Map<String, dynamic>> messages,
  ) async {
    final keysToUpdate = messages
        .where(_shouldMarkAsRead)
        .map((message) => message['key']?.toString() ?? '')
        .where((key) => key.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (keysToUpdate.isEmpty) {
      return;
    }

    _readReceiptInFlight.addAll(keysToUpdate);

    try {
      await ChatService.markMessagesAsRead(
        chatRoomId: widget.chatRoomId,
        messageKeys: keysToUpdate,
      );

      if (!mounted) {
        return;
      }

      final updatedKeys = keysToUpdate.toSet();
      setState(() {
        for (final message in _messages) {
          final key = message['key']?.toString() ?? '';
          if (updatedKeys.contains(key)) {
            message['isRead'] = true;
          }
        }
      });
    } catch (e, st) {
      debugPrint('Failed to mark messages as read: $e\n$st');
    } finally {
      _readReceiptInFlight.removeAll(keysToUpdate);
    }
  }

  void _scrollToBottom({required bool instant}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (instant || _isInitialLoad) {
        _scrollController.jumpTo(maxScroll);
        _isInitialLoad = false;
        return;
      }

      if (maxScroll > currentScroll && (maxScroll - currentScroll) <= 300) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatLastSeen(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return 'Offline';

    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Last seen ${_formatTime(timestamp)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Last seen yesterday';
    }

    const months = <String>[
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

  Future<void> _sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    try {
      await ChatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        text: trimmedText,
        receiverId: widget.otherUserId,
      );
      if (_messageController.text.trim() == trimmedText) {
        _messageController.clear();
      }
      _isLocalTyping = false;
      ChatService.setTypingStatus(widget.chatRoomId, false);
      _typingTimer?.cancel();
      _scrollToBottom(instant: false);
    } catch (_) {
      _showErrorSnackBar('Failed to send message.');
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (pickedFile == null) return;

      await ChatService.sendImageMessage(
        chatRoomId: widget.chatRoomId,
        imageFile: File(pickedFile.path),
        receiverId: widget.otherUserId,
      );

      if (mounted) {
        _scrollToBottom(instant: false);
      }
    } catch (e) {
      debugPrint('Failed to send image: $e');
      _showErrorSnackBar('Failed to send image.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showImagePreview(String imageUrl) {
    if (imageUrl.trim().isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox(
                  height: 280,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  height: 280,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _messageTypeFor(Map<String, dynamic> data) {
    final explicitType = data['messageType']?.toString().trim() ?? '';
    if (explicitType.isNotEmpty) return explicitType;

    final imageUrl = data['imageUrl']?.toString().trim() ?? '';
    return imageUrl.isNotEmpty
        ? ChatService.imageMessageType
        : ChatService.textMessageType;
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
      backgroundColor: const Color(0xFFF4F8FB),
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
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              backgroundImage: widget.otherUserImage.isNotEmpty
                  ? CachedNetworkImageProvider(widget.otherUserImage)
                  : null,
              child: widget.otherUserImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
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
                  ChatHeaderStatus(
                    chatRoomId: widget.chatRoomId,
                    otherUserId: widget.otherUserId,
                    itemTitle: widget.itemTitle,
                    formatLastSeen: _formatLastSeen,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.itemImage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () => _showImagePreview(widget.itemImage),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: widget.itemImage,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
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
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesArea()),
          _buildTypingIndicator(),
          _ChatComposer(
            controller: _messageController,
            onSendMessage: _sendMessage,
            onSendImage: _pickAndSendImage,
          ),
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
          padding: const EdgeInsets.all(24),
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD7E4EE)),
          ),
          child: Text(
            'No messages yet.\nStart the conversation!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4F8FB), Color(0xFFEFF5FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        cacheExtent: 600,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final data = _messages[index];
          final senderId = data['senderId']?.toString() ?? '';

          return KeyedSubtree(
            key: ValueKey<String>(data['key']?.toString() ?? '$index'),
            child: ChatMessageBubble(
              text: data['text']?.toString() ?? '',
              imageUrl: data['imageUrl']?.toString().trim() ?? '',
              messageType: _messageTypeFor(data),
              timeString: _formatTime(_timestampOf(data)),
              isMe: senderId == widget.currentUserId,
              isRead: ChatService.isMessageRead(data),
              otherUserImage: widget.otherUserImage,
              onImageTap: () =>
                  _showImagePreview(data['imageUrl']?.toString().trim() ?? ''),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DatabaseEvent>(
      stream: ChatService.getTypingStatusStream(
        widget.chatRoomId,
        widget.otherUserId,
      ),
      builder: (context, snapshot) {
        var isTyping = false;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value;
          if (data is Map) {
            isTyping = data['isTyping'] == true;
          }
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            );
          },
          child: isTyping
              ? Padding(
                  key: const ValueKey('typing-indicator'),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FloatingTypingIndicator(
                      otherUserImage: widget.otherUserImage,
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('typing-indicator-empty')),
        );
      },
    );
  }
}

class _ChatComposer extends StatefulWidget {
  const _ChatComposer({
    required this.controller,
    required this.onSendMessage,
    required this.onSendImage,
  });

  final TextEditingController controller;
  final Future<void> Function(String text) onSendMessage;
  final Future<void> Function(ImageSource source) onSendImage;

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  bool _isSending = false;
  bool _isUploadingImage = false;

  bool get _isComposerBusy => _isSending || _isUploadingImage;

  Future<void> _handleSend() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty || _isComposerBusy) return;

    setState(() => _isSending = true);
    try {
      await widget.onSendMessage(text);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleImagePick(ImageSource source) async {
    if (_isComposerBusy) return;

    setState(() => _isUploadingImage = true);
    try {
      await widget.onSendImage(source);
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _showImagePickerSheet() async {
    if (_isComposerBusy) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF7FB),
                  child: Icon(Icons.photo_library, color: Color(0xFF113F67)),
                ),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImagePick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF7FB),
                  child: Icon(Icons.photo_camera, color: Color(0xFF113F67)),
                ),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImagePick(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEAF7FB),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isUploadingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Color(0xFF113F67),
                      ),
                onPressed: _isComposerBusy ? null : _showImagePickerSheet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FAFD),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFD7E4EE)),
                ),
                child: TextField(
                  controller: widget.controller,
                  maxLines: null,
                  enabled: !_isUploadingImage,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: _isComposerBusy
                    ? const Color(0xFF7ACEE3)
                    : const Color(0xFF16BCE6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _isComposerBusy ? null : _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
