import 'package:flutter/material.dart';
import 'package:rentals/services/favorites_service.dart';
import 'package:rentals/widgets/app_feedback.dart';

class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({
    super.key,
    required this.deal,
    this.size = 18,
    this.likedColor = const Color(0xFF16BCE6),
    this.unlikedColor = const Color(0xFF9BAFBE),
  });

  final Map<String, dynamic> deal;
  final double size;
  final Color likedColor;
  final Color unlikedColor;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _scaleAnimation =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 1.16,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 45,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1.16,
            end: 0.96,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0.96,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 30,
        ),
      ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap(
    BuildContext context,
    String rentalId,
    bool isLiked,
  ) async {
    if (rentalId.isEmpty || rentalId == 'unknown_id') {
      return;
    }

    _controller.forward(from: 0);

    try {
      await FavoritesService.toggleFavorite(widget.deal);
      if (!context.mounted) {
        return;
      }

      AppFeedback.showSuccess(
        context,
        title: isLiked ? 'Removed from Saved' : 'Saved to Favorites',
        message: isLiked
            ? 'This item was removed from your liked list.'
            : 'This item was added to your liked list.',
      );
    } catch (_) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          title: 'Action Failed',
          message: 'Failed to update favorites.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String rentalId = FavoritesService.getRentalId(widget.deal);
    final favoriteIdsListenable = FavoritesService.favoriteIdsListenable();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: favoriteIdsListenable,
      builder: (context, favoriteIds, child) {
        final isLiked = favoriteIds.contains(rentalId);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleTap(context, rentalId, isLiked),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.88, end: 1).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                key: ValueKey<bool>(isLiked),
                size: widget.size,
                color: isLiked ? widget.likedColor : widget.unlikedColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
