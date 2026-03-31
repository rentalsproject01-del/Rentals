import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.backgroundColor = const Color(0xFFE9EEF3),
    this.emptyIcon = Icons.image_not_supported,
    this.errorIcon = Icons.broken_image_outlined,
    this.progressColor = const Color(0xFF16BCE6),
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Color backgroundColor;
  final IconData emptyIcon;
  final IconData errorIcon;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.isEmpty) {
      return _buildFallback(emptyIcon);
    }

    return CachedNetworkImage(
      imageUrl: trimmedUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: memCacheWidth,
      maxHeightDiskCache: memCacheHeight,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      filterQuality: FilterQuality.low,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildFallback(errorIcon),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      alignment: Alignment.center,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: progressColor),
      ),
    );
  }

  Widget _buildFallback(IconData icon) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.grey, size: 28),
    );
  }
}
