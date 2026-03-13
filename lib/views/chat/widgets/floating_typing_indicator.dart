import 'package:flutter/material.dart';

import 'typing_dots_indicator.dart';

class FloatingTypingIndicator extends StatelessWidget {
  const FloatingTypingIndicator({super.key, required this.otherUserImage});

  final String otherUserImage;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFFD7E4EE),
            backgroundImage: otherUserImage.isNotEmpty
                ? NetworkImage(otherUserImage)
                : null,
            child: otherUserImage.isEmpty
                ? const Icon(Icons.person, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFEFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD8E5EF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const TypingDotsIndicator(
              activeColor: Color(0xFF16BCE6),
              inactiveColor: Color(0x663D7490),
              dotSize: 6,
              spacing: 4,
              bounceOffset: 2.5,
              minScale: 0.7,
              maxScale: 1.02,
            ),
          ),
        ],
      ),
    );
  }
}
