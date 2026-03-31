import 'package:flutter/material.dart';
import 'package:rentals/widgets/animated_like_button.dart';
import 'package:rentals/widgets/app_network_image.dart';
import 'package:rentals/widgets/pressable_scale.dart';

class DealItemCard extends StatelessWidget {
  const DealItemCard({super.key, required this.deal, required this.onTap});

  final Map<String, dynamic> deal;
  final VoidCallback onTap;

  static const Color _brandPrimary = Color(0xFF113F67);
  static const Color _brandAccent = Color(0xFF16BCE6);

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _extractPrimaryImageUrl(deal);
    final String title = _readText(deal['title'], fallback: 'Unknown Item');
    final String subtitle = _resolveSubtitle();
    final String priceText = _formatPrice(deal['price']);
    final String duration = _normalizeDuration(_readText(deal['duration']));
    final String ratingText = _formatRating(deal['rating']);

    return PressableScale(
      onTap: onTap,
      scaleDown: 0.985,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: _brandPrimary.withValues(alpha: 0.78)),
          boxShadow: [
            BoxShadow(
              color: _brandPrimary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.34,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFF8C8),
                              const Color(0xFFFFF2A6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: AppNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          memCacheWidth: 720,
                          memCacheHeight: 520,
                          backgroundColor: const Color(0xFFFFF8C8),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _brandAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: _brandAccent.withValues(alpha: 0.24),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedLikeButton(
                            deal: deal,
                            size: 15,
                            likedColor: Colors.white,
                            unlikedColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _brandPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        height: 1.05,
                      ),
                    ),
                  ),
                  if (ratingText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _RatingBadge(ratingText: ratingText),
                  ],
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Rent at ',
                      style: TextStyle(
                        color: _brandPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: '₹$priceText',
                      style: const TextStyle(
                        color: _brandPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (duration.isNotEmpty)
                      TextSpan(
                        text: '/$duration',
                        style: const TextStyle(
                          color: _brandPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveSubtitle() {
    final String subcategory = _readText(deal['subcategory']);
    if (subcategory.isNotEmpty) {
      return subcategory;
    }

    final String category = _readText(deal['category']);
    if (category.isNotEmpty) {
      return category;
    }

    return _readText(deal['ownerName']);
  }

  static String _extractPrimaryImageUrl(Map<String, dynamic> deal) {
    final imageUrls = deal['imageUrls'];

    if (imageUrls is List) {
      for (final image in imageUrls) {
        final String url = image?.toString().trim() ?? '';
        if (url.isNotEmpty) {
          return url;
        }
      }
    }

    if (imageUrls is String && imageUrls.trim().isNotEmpty) {
      return imageUrls.trim();
    }

    return '';
  }

  static String _readText(dynamic value, {String fallback = ''}) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _formatPrice(dynamic value) {
    if (value == null) {
      return '0';
    }

    if (value is num) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(0);
    }

    final String raw = value.toString().trim();
    if (raw.isEmpty) {
      return '0';
    }

    final num? parsed = num.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    if (parsed % 1 == 0) {
      return parsed.toInt().toString();
    }

    return parsed.toStringAsFixed(0);
  }

  static String _formatRating(dynamic value) {
    final String raw = value?.toString().trim() ?? '';
    if (raw.isEmpty || raw.toLowerCase() == 'n/a') {
      return '';
    }

    final double? parsed = double.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    return parsed.toStringAsFixed(parsed % 1 == 0 ? 0 : 1);
  }

  static String _normalizeDuration(String value) {
    final String normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.contains('day')) {
      return 'day';
    }
    if (normalized.contains('week')) {
      return 'week';
    }
    if (normalized.contains('month')) {
      return 'month';
    }
    if (normalized.contains('hour')) {
      return 'hour';
    }

    return value.trim();
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.ratingText});

  final String ratingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DealItemCard._brandAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ratingText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, color: Colors.white, size: 14),
        ],
      ),
    );
  }
}
