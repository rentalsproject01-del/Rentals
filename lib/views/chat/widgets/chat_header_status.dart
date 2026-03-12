import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:rentals/services/chat_service.dart';

import 'typing_dots_indicator.dart';

class ChatHeaderStatus extends StatelessWidget {
  const ChatHeaderStatus({
    super.key,
    required this.chatRoomId,
    required this.otherUserId,
    required this.itemTitle,
    required this.formatLastSeen,
  });

  final String chatRoomId;
  final String otherUserId;
  final String itemTitle;
  final String Function(int? timestamp) formatLastSeen;

  @override
  Widget build(BuildContext context) {
    final itemDisplay = itemTitle.isNotEmpty ? itemTitle : 'Item Inquiry';

    return StreamBuilder<DatabaseEvent>(
      stream: ChatService.getTypingStatusStream(chatRoomId, otherUserId),
      builder: (context, typingSnapshot) {
        var isTyping = false;
        if (typingSnapshot.hasData &&
            typingSnapshot.data!.snapshot.value != null) {
          final data = typingSnapshot.data!.snapshot.value;
          if (data is Map) {
            isTyping = data['isTyping'] == true;
          }
        }

        if (isTyping) {
          return Row(
            children: [
              Flexible(
                child: Text(
                  itemDisplay,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '•',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const TypingDotsIndicator(),
            ],
          );
        }

        return StreamBuilder<DatabaseEvent>(
          stream: ChatService.getUserStatusStream(otherUserId),
          builder: (context, snapshot) {
            var statusText = 'Offline';
            var isOnline = false;
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = snapshot.data!.snapshot.value;
              if (data is Map) {
                isOnline = data['isOnline'] == true;
                if (isOnline) {
                  statusText = 'Online';
                } else if (data['lastSeen'] is num) {
                  statusText = formatLastSeen(
                    (data['lastSeen'] as num).toInt(),
                  );
                }
              }
            }

            return Row(
              children: [
                Flexible(
                  child: Text(
                    itemDisplay,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '•',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                Flexible(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: isOnline ? Colors.greenAccent : Colors.white70,
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
    );
  }
}
