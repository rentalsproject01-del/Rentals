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
    required this.isRead,
    required this.otherUserImage,
    required this.onImageTap,
  });

  final String text;
  final String imageUrl;
  final String messageType;
  final String timeString;
  final bool isMe;
  final bool isRead;
  final String otherUserImage;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    final isImageMessage =
        messageType == ChatService.imageMessageType && imageUrl.isNotEmpty;
    final bubbleColor = isMe ? const Color(0xFF1A4D74) : Colors.white;
    final textColor = isMe ? Colors.white : const Color(0xFF132535);
    final metaColor = isMe ? Colors.white70 : const Color(0xFF6C7A86);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                  ? CachedNetworkImageProvider(otherUserImage)
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
              padding: EdgeInsets.fromLTRB(
                isImageMessage ? 6 : 12,
                isImageMessage ? 6 : 9,
                isImageMessage ? 6 : 12,
                8,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(color: const Color(0xFFD8E3EC)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isImageMessage)
                    GestureDetector(
                      onTap: onImageTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 220,
                            height: 180,
                            color: isMe
                                ? const Color(0xFF2A638F)
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
                                ? const Color(0xFF2A638F)
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
                      padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (!isImageMessage)
                    Text(
                      text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          color: metaColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 15,
                          color: isRead
                              ? const Color(0xFF91E4FF)
                              : Colors.white70,
                        ),
                      ],
                    ],
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
