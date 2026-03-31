import 'package:flutter/material.dart';
import 'package:rentals/widgets/app_network_image.dart';

class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({super.key, required this.images});

  final List<String> images;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _currentImageIndex = 0;

  @override
  void didUpdateWidget(covariant ProductImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentImageIndex >= widget.images.length) {
      _currentImageIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 380,
        width: double.infinity,
        child: Stack(
          children: [
            widget.images.isNotEmpty
                ? PageView.builder(
                    itemCount: widget.images.length,
                    onPageChanged: (index) {
                      if (_currentImageIndex == index) return;
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return AppNetworkImage(
                        imageUrl: widget.images[index],
                        width: double.infinity,
                        height: double.infinity,
                        memCacheWidth: 1440,
                        memCacheHeight: 1440,
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? const Color(0xFF113F67)
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
