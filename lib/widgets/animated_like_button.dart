import 'package:flutter/material.dart';
import 'package:rentals/services/favorites_service.dart';

class AnimatedLikeButton extends StatelessWidget {
  const AnimatedLikeButton({super.key, required this.deal});

  final Map<String, dynamic> deal;

  @override
  Widget build(BuildContext context) {
    final String rentalId = FavoritesService.getRentalId(deal);

    return StreamBuilder<bool>(
      stream: FavoritesService.isFavoriteStream(rentalId),
      builder: (context, snapshot) {
        final bool isLiked = snapshot.data ?? false;

        return GestureDetector(
          onTap: () async {
            if (rentalId.isEmpty || rentalId == 'unknown_id') return;
            try {
              await FavoritesService.toggleFavorite(deal);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update favorites.')),
                );
              }
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Image.asset(
              isLiked
                  ? 'assets/icons/like_icon3.png'
                  : 'assets/icons/like_icon.png',
              key: ValueKey<bool>(isLiked),
              height: 14,
              width: 14,
              errorBuilder: (c, e, s) => Icon(
                isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                size: 14,
                color: isLiked ? Colors.red : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
