import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductOwnerSection extends StatelessWidget {
  const ProductOwnerSection({
    super.key,
    required this.ownerImage,
    required this.ownerName,
    required this.isLoadingOwner,
    required this.isOpeningChat,
    required this.onOpenOwnerProfile,
    required this.onCallSeller,
    required this.onOpenChat,
  });

  final String ownerImage;
  final String ownerName;
  final bool isLoadingOwner;
  final bool isOpeningChat;
  final VoidCallback onOpenOwnerProfile;
  final VoidCallback onCallSeller;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onOpenOwnerProfile,
          child: ClipOval(
            child: ownerImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ownerImage,
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      width: 55,
                      height: 55,
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF16BCE6),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenOwnerProfile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Owner',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                isLoadingOwner
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF113F67),
                        ),
                      )
                    : Text(
                        ownerName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF113F67),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ),
        _buildActionButton(
          icon: const Icon(
            Icons.call_outlined,
            color: Color(0xFF16BCE6),
            size: 22,
          ),
          onPressed: onCallSeller,
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: isOpeningChat
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF16BCE6),
                  ),
                )
              : const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF16BCE6),
                  size: 22,
                ),
          onPressed: isOpeningChat ? null : onOpenChat,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16BCE6).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(onPressed: onPressed, icon: icon),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 55,
      height: 55,
      color: Colors.grey[200],
      child: const Icon(Icons.person, color: Colors.grey, size: 30),
    );
  }
}
