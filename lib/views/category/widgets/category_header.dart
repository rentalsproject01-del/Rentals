import 'package:flutter/material.dart';
import 'package:rentals/widgets/animated_search_bar.dart';

class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    super.key,
    required this.categoryName,
    required this.onBack,
    required this.onSearchTap,
  });

  final String categoryName;
  final VoidCallback onBack;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Image.asset(
                  'assets/icons/arrow_back_icon.png',
                  height: 18,
                  color: Colors.white,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                categoryName,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: AnimatedSearchBar(onTap: onSearchTap)),
              const SizedBox(width: 20),
              Image.asset(
                'assets/icons/like_icon.png',
                height: 20,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
