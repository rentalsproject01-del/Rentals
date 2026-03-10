import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/services/favorites_service.dart';

class LikePage extends StatefulWidget {
  const LikePage({super.key});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/icons/arrow_icon.png',
                      height: 24,
                      width: 24,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Like',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // --- MAIN CONTENT (White Container) ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FavoritesService.getFavoriteItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF16BCE6),
                          ),
                        );
                      }

                      final likedItems = snapshot.data ?? [];

                      if (likedItems.isEmpty) {
                        return const Center(
                          child: Text(
                            "No Liked Items Yet",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: likedItems.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 30, color: Colors.grey),
                        itemBuilder: (context, index) {
                          return ProductCard(
                            deal: likedItems[index],
                            onUnlike: () {
                              FavoritesService.toggleFavorite(
                                likedItems[index],
                              );
                            },
                          );
                        },
                      );
                    },
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

// --- PRODUCT CARD WIDGET ---
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> deal;
  final VoidCallback onUnlike;

  const ProductCard({super.key, required this.deal, required this.onUnlike});

  @override
  Widget build(BuildContext context) {
    String imageUrl = '';
    if (deal['imageUrls'] != null && (deal['imageUrls'] as List).isNotEmpty) {
      imageUrl = deal['imageUrls'][0].toString();
    } else if (deal['imageUrls'] is String) {
      imageUrl = deal['imageUrls'].toString();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Section
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 150,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 150,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF16BCE6),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 150,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              : Container(
                  width: 150,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
        ),
        const SizedBox(width: 12),

        // Info Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      deal['title'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF113F67),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Animated Like Button (Unliking)
                  GestureDetector(
                    onTap: onUnlike,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Image.asset(
                        'assets/icons/like_icon3.png', // Liked icon
                        key: const ValueKey('liked'),
                        height: 20,
                        width: 20,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                deal['subcategory'] ?? deal['category'] ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF113F67),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      deal['rating']?.toString() ?? 'N/A',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      'assets/icons/star_icon.png',
                      height: 12,
                      width: 12,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.star, size: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Price and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rs. ${deal['price'] ?? '0'}",
                    style: const TextStyle(
                      color: Color(0xFF113F67),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductPage(productData: deal),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      width: 55,
                      height: 27,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF113F67)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        "assets/icons/rent_icon.png",
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Color(0xFF113F67),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
