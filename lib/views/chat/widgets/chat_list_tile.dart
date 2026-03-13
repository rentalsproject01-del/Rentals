import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:rentals/services/chat_service.dart';

import 'typing_dots_indicator.dart';

class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.chatRoomId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    required this.itemTitle,
    required this.itemImage,
    required this.lastMessage,
    required this.formattedTime,
    required this.onTap,
  });

  final String chatRoomId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;
  final String itemTitle;
  final String itemImage;
  final String lastMessage;
  final String formattedTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: otherUserImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: otherUserImage,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildAvatarPlaceholder(),
                          errorWidget: (context, url, error) =>
                              _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: StreamBuilder<DatabaseEvent>(
                    stream: ChatService.getUserStatusStream(otherUserId),
                    builder: (context, statusSnapshot) {
                      bool isOnline = false;
                      if (statusSnapshot.hasData &&
                          statusSnapshot.data!.snapshot.value != null) {
                        final statusData = statusSnapshot.data!.snapshot.value;
                        if (statusData is Map) {
                          isOnline = statusData['isOnline'] == true;
                        }
                      }

                      if (!isOnline) return const SizedBox.shrink();

                      return Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent[400],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF113F67),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    itemTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF16BCE6),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<DatabaseEvent>(
                    stream: ChatService.getTypingStatusStream(
                      chatRoomId,
                      otherUserId,
                    ),
                    builder: (context, typingSnapshot) {
                      bool isTyping = false;
                      if (typingSnapshot.hasData &&
                          typingSnapshot.data!.snapshot.value != null) {
                        final typingData = typingSnapshot.data!.snapshot.value;
                        if (typingData is Map) {
                          isTyping = typingData['isTyping'] == true;
                        }
                      }

                      if (isTyping) {
                        return const Row(
                          children: [
                            Text(
                              'Typing',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0FA9CE),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6),
                            TypingDotsIndicator(
                              activeColor: Color(0xFF0FA9CE),
                              inactiveColor: Color(0x4016BCE6),
                              dotSize: 5,
                              spacing: 3,
                              bounceOffset: 2.5,
                            ),
                          ],
                        );
                      }

                      return Text(
                        lastMessage.isNotEmpty
                            ? lastMessage
                            : 'Start the conversation',
                        style: TextStyle(
                          fontSize: 14,
                          color: lastMessage.isNotEmpty
                              ? Colors.black87
                              : Colors.grey.shade400,
                          fontStyle: lastMessage.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ],
              ),
            ),
            if (itemImage.isNotEmpty) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: itemImage,
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(width: 45, height: 45, color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    width: 45,
                    height: 45,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: Colors.grey[200],
      child: const Icon(Icons.person, color: Colors.grey, size: 26),
    );
  }
}
