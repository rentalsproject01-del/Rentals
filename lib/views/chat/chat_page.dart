import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentals/services/chat_service.dart';
import 'package:rentals/views/chat/chat_room_page.dart';
import 'package:rentals/views/chat/widgets/chat_list_tile.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = ChatService.getCurrentUserId();
  }

  Future<void> _openChatRoom({
    required String chatRoomId,
    required String fallbackOtherUserId,
    required String fallbackOtherUserName,
    required String fallbackOtherUserImage,
    required String fallbackItemTitle,
    required String fallbackItemImage,
  }) async {
    final currentUserId = this.currentUserId;
    if (chatRoomId.isEmpty || currentUserId == null) return;

    final resolvedData = await ChatService.resolveChatRoomNavigationData(
      chatRoomId: chatRoomId,
      currentUserId: currentUserId,
    );

    final otherUserId =
        resolvedData?['otherUserId']?.toString() ?? fallbackOtherUserId;
    if (otherUserId.isEmpty || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          chatRoomId: chatRoomId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          otherUserName:
              resolvedData?['otherUserName']?.toString() ??
              fallbackOtherUserName,
          otherUserImage:
              resolvedData?['otherUserImage']?.toString() ??
              fallbackOtherUserImage,
          itemTitle:
              resolvedData?['itemTitle']?.toString() ?? fallbackItemTitle,
          itemImage:
              resolvedData?['itemImage']?.toString() ?? fallbackItemImage,
        ),
      ),
    );
  }

  /// Formats the Firestore Timestamp into a readable string
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final DateTime date = timestamp.toDate();
    final DateTime now = DateTime.now();

    // If it's today, show HH:MM
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    // Otherwise show DD/MM
    else {
      final String day = date.day.toString().padLeft(2, '0');
      final String month = date.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67), // Dark blue header background
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text(
                'Chats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // --- MAIN CONTENT ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: currentUserId == null
                      ? const Center(
                          child: Text(
                            "Please log in to view your chats.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : _buildChatList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: ChatService.getUserChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF113F67)),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Something went wrong while loading chats.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No conversations yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.only(
            top: 15,
            bottom: 100,
          ), // Padding for navbar
          itemCount: docs.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey.shade200,
            height: 1,
            indent: 85,
            endIndent: 20,
          ),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildChatTile(data);
          },
        );
      },
    );
  }

  Widget _buildChatTile(Map<String, dynamic> data) {
    final String ownerId = data['ownerId']?.toString() ?? '';
    final String ownerName = data['ownerName']?.toString() ?? 'Unknown Owner';
    final String ownerImage = data['ownerImage']?.toString() ?? '';

    final String renterId = data['renterId']?.toString() ?? '';
    final String renterName =
        data['renterName']?.toString() ?? 'Unknown Renter';
    final String renterImage = data['renterImage']?.toString() ?? '';

    final String itemTitle = data['itemTitle']?.toString() ?? 'Unknown Item';
    final String itemImage = data['itemImage']?.toString() ?? '';
    final String lastMessage = data['lastMessage']?.toString() ?? '';
    final Timestamp? lastMessageTime = data['lastMessageTime'] as Timestamp?;
    final String chatRoomId = data['chatRoomId']?.toString() ?? '';

    final bool isOwner = currentUserId == ownerId;
    final String otherUserId = isOwner ? renterId : ownerId;
    final String otherUserName = isOwner ? renterName : ownerName;
    final String otherUserImage = isOwner ? renterImage : ownerImage;

    return ChatListTile(
      chatRoomId: chatRoomId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserImage: otherUserImage,
      itemTitle: itemTitle,
      itemImage: itemImage,
      lastMessage: lastMessage,
      formattedTime: _formatTime(lastMessageTime),
      onTap: () {
        _openChatRoom(
          chatRoomId: chatRoomId,
          fallbackOtherUserId: otherUserId,
          fallbackOtherUserName: otherUserName,
          fallbackOtherUserImage: otherUserImage,
          fallbackItemTitle: itemTitle,
          fallbackItemImage: itemImage,
        );
      },
    );
  }
}
