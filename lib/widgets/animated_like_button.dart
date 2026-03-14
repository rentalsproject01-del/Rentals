import 'package:flutter/material.dart';
import 'package:rentals/services/favorites_service.dart';

class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({super.key, required this.deal, this.size = 18});

  final Map<String, dynamic> deal;
  final double size;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  static const Color _likedColor = Color(0xFF16BCE6);
  static const Color _unlikedColor = Color(0xFF9BAFBE);

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

  Future<void> _handleTap(BuildContext context, String rentalId) async {
    if (rentalId.isEmpty || rentalId == 'unknown_id') {
      return;
    }

    _controller.forward(from: 0);

    try {
      await FavoritesService.toggleFavorite(widget.deal);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorites.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String rentalId = FavoritesService.getRentalId(widget.deal);

    return StreamBuilder<bool>(
      stream: FavoritesService.isFavoriteStream(rentalId),
      builder: (context, snapshot) {
        final bool isLiked = snapshot.data ?? false;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleTap(context, rentalId),
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
                color: isLiked ? _likedColor : _unlikedColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
