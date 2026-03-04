import 'package:flutter/material.dart';
import 'package:rentals/product_page.dart';

class LikePage extends StatelessWidget {
  const LikePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data based on your image
    final List<Product> products = [
      Product("The Rose Gold Jewellery", "Bracelet | Necklace | Earrings | Rings", 3.7, "assets/images/jwellery.png"),
      Product("Zara Tied Satin Effect Front Blazer", "Hot Pink Jacket & Coat", 4.7, "assets/images/jacket_img.png"),
      Product("Sony Camera", "a7 | Mirrorless", 3.3, "assets/images/camera_img.png"),
      Product("JBL Speaker", "Portable", 4.3, "assets/images/speaker_img.png"),
      Product("Hooked", "Author Nir Eyal", 4.7, "assets/images/book_img2.png"),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF113F67), // Dark blue header area
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
                    child: Image.asset('assets/icons/arrow_icon.png', height: 24, width: 24),
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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const Divider(height: 30, color: Colors.grey),
                    itemBuilder: (context, index) {
                      return ProductCard(product: products[index]);
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
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Section
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            product.imagePath,
            width: 150,
            height: 100,
            fit: BoxFit.cover,
            // Fallback if image not found
            errorBuilder: (context, error, stackTrace) => Container(
              width: 150, height: 100, color: Colors.grey[300],
              child: const Icon(Icons.image),
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
                      product.title,
                      style: const TextStyle(color: Color(0xFF113F67), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Image.asset('assets/icons/like_icon2.png', height: 20, width: 20,)
                ],
              ),
              Text(
                product.subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                      product.rating.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    const SizedBox(width: 2),
                    Image.asset('assets/icons/star_icon.png', height: 12, width: 12,),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Price and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Rs.",
                    style: TextStyle(
                      color: Color(0xFF113F67),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProductPage()),
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
                        child: Image.asset("assets/icons/rent_icon.png", ),
                      ),
                    )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- DATA MODEL ---
class Product {
  final String title;
  final String subtitle;
  final double rating;
  final String imagePath;

  Product(this.title, this.subtitle, this.rating, this.imagePath);
}