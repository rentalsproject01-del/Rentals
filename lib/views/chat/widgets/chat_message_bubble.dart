import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rentals/services/chat_service.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.imageUrl,
    required this.messageType,
    required this.timeString,
    required this.isMe,
    required this.otherUserImage,
    required this.onImageTap,
  });

  final String text;
  final String imageUrl;
  final String messageType;
  final String timeString;
  final bool isMe;
  final String otherUserImage;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    final isImageMessage =
        messageType == ChatService.imageMessageType && imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              backgroundImage: otherUserImage.isNotEmpty
                  ? NetworkImage(otherUserImage)
                  : null,
              child: otherUserImage.isEmpty
                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: EdgeInsets.all(isImageMessage ? 6 : 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF113F67) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                border: isMe
                    ? null
                    : Border.all(color: const Color(0xFFDCE6EE)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (isImageMessage)
                    GestureDetector(
                      onTap: onImageTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 220,
                            height: 180,
                            color: isMe
                                ? const Color(0xFF245986)
                                : const Color(0xFFEAF2F8),
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              color: isMe
                                  ? Colors.white70
                                  : const Color(0xFF113F67),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 220,
                            height: 180,
                            color: isMe
                                ? const Color(0xFF245986)
                                : const Color(0xFFEAF2F8),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: isMe
                                      ? Colors.white70
                                      : const Color(0xFF113F67),
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image unavailable',
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : const Color(0xFF113F67),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isImageMessage && text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (!isImageMessage)
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  const SizedBox(height: 6),
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
}
