import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/services/rental_service.dart';
import 'package:rentals/views/home/home_page.dart';
import 'package:rentals/views/search/search_page.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;

  const CategoryPage({super.key, required this.categoryName});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  int _selectedSubCategoryIndex = 0;

  final Map<String, List<String>> categorySubMap = {
    'Fashion': [
      'All',
      'Jacket',
      'Dress',
      'Kurta/Kurti',
      'Footwear',
      'Scarf',
      'Other',
    ],
    'Jewellery': [
      'All',
      'Necklace',
      'Earrings',
      'Anklet',
      'Bangles/Bracelets',
      'Bridal set',
      'Other',
    ],
    'Vehicle': ['All', 'Cars', 'Bike', 'Scooter', 'Bicycle', 'skates', 'Other'],
    'House': [
      'All',
      'Apartment/Flat',
      'Independant House',
      'Rooms',
      'PG/Hostel',
      'Commerical Space',
      'Other',
    ],
    'Electronics': [
      'All',
      'Speaker',
      'Camera',
      'Projector',
      'Laptop/Phone',
      'Watch',
      'Other',
    ],
    'Books': [
      'All',
      'Story/Poetry',
      'Academic book',
      'Fiction Novel',
      'Non-Fictional',
      'Children’s book',
      'Other',
    ],
    'Game': [
      'All',
      'VR Headset',
      'Playstation',
      'Gaming Console',
      'Game Equipment',
      'Game Drive',
      'Other',
    ],
    'GYM': [
      'All',
      'Dumbbells',
      'Yoga mats',
      'Gym Bag',
      'Gym equipment',
      'Fitness Band',
      'Other',
    ],
    'Travel': [
      'All',
      'Camping Tent',
      'Bags',
      'Sleeping Bags',
      'Portable Stove',
      'Water Bottles/Thermos',
      'Other',
    ],
    'Decore': [
      'All',
      'Lights',
      'Artificial Flowers/plants',
      'Theme party props',
      'Stage',
      'Mandap decore',
      'Other',
    ],
    'Furniture': [
      'All',
      'Mattress',
      'Rack/Cabinet',
      'Folding Table/chair',
      'Bench',
      'Baby Crib',
      'Other',
    ],
    'Subscription': [
      'All',
      'OTT/Streaming',
      'Music',
      'Gaming',
      'Education',
      'Software/Tool',
      'Other',
    ],
    'Other': ['All', 'Other'],
  };

  List<String> get currentSubCategories =>
      categorySubMap[widget.categoryName] ?? ['All', 'Other'];

  void _openSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 15),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftSidebar(),
                    Expanded(child: _buildRightGrid()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
                widget.categoryName,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: AnimatedSearchBar(onTap: _openSearchScreen)),
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

  Widget _buildLeftSidebar() {
    return Container(
      width: 85,
      decoration: const BoxDecoration(
        color: Color(0xFFDDF3FA),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(35)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 25, bottom: 20),
        itemCount: currentSubCategories.length,
        itemBuilder: (context, index) {
          final subCat = currentSubCategories[index];
          final isSelected = _selectedSubCategoryIndex == index;

          String formattedAssetName = subCat
              .toLowerCase()
              .replaceAll(' ', '_')
              .replaceAll('/', '_')
              .replaceAll('’', '')
              .replaceAll('-', '_');

          return GestureDetector(
            onTap: () => setState(() => _selectedSubCategoryIndex = index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF00A2FF), Color(0xFF16BCE6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFF70C6E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/icons/$formattedAssetName.png',
                        height: 40,
                        width: 40,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          isSelected ? Icons.check_circle : Icons.image,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subCat,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF113F67)
                          : const Color(0xFF00A2FF),
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: RentalService.getAllRentals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF113F67)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No items available",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final selectedSubCategory =
            currentSubCategories[_selectedSubCategoryIndex];
        List<Map<String, dynamic>> filteredItems = [];

        for (var doc in snapshot.data!.docs) {
          final data = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );
          data['id'] = doc.id;

          if (data['category'] == widget.categoryName) {
            if (selectedSubCategory == 'All' ||
                data['subcategory'] == selectedSubCategory) {
              filteredItems.add(data);
            }
          }
        }

        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              "No items in $selectedSubCategory",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(
            top: 25,
            left: 15,
            right: 15,
            bottom: 20,
          ),
          itemCount: filteredItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            return _buildDealCard(context, filteredItems[index]);
          },
        );
      },
    );
  }

  Widget _buildDealCard(BuildContext context, Map<String, dynamic> deal) {
    String imageUrl = '';

    if (deal['imageUrls'] != null) {
      if (deal['imageUrls'] is List && (deal['imageUrls'] as List).isNotEmpty) {
        imageUrl = deal['imageUrls'][0].toString();
      } else if (deal['imageUrls'] is String &&
          (deal['imageUrls'] as String).isNotEmpty) {
        imageUrl = deal['imageUrls'].toString();
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(productData: deal),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF113F67).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              height: 100,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
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
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              height: 100,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF113F67).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AnimatedLikeButton(deal: deal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal['title']?.toString() ?? 'Unknown Item',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xFF113F67),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                deal['ownerName']?.toString() ??
                                    'Unknown Owner',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            "Rs. ${deal['price'] ?? '0'}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Color(0xFF113F67),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          width: 38,
                          height: 26,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF113F67),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/icons/rent_icon.png",
                              height: 12,
                              width: 12,
                              color: const Color(0xFF113F67),
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF113F67),
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
