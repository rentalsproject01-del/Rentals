import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentals/services/rental_service.dart';
import 'package:rentals/views/category/widgets/category_deal_card.dart';
import 'package:rentals/views/category/widgets/category_header.dart';
import 'package:rentals/views/category/widgets/category_sidebar.dart';
import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/views/search/search_page.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;

  const CategoryPage({super.key, required this.categoryName});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  int _selectedSubCategoryIndex = 0;
  late final Stream<QuerySnapshot> _rentalsStream;
  QuerySnapshot? _lastSnapshot;
  final Map<String, List<Map<String, dynamic>>> _filteredItemsCache =
      <String, List<Map<String, dynamic>>>{};

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
      'Childrenâ€™s book',
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
  void initState() {
    super.initState();
    _rentalsStream = RentalService.getAllRentals();
  }

  @override
  void didUpdateWidget(covariant CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryName != widget.categoryName) {
      _selectedSubCategoryIndex = 0;
      _filteredItemsCache.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CategoryHeader(
              categoryName: widget.categoryName,
              onBack: () => Navigator.pop(context),
              onSearchTap: _openSearchScreen,
            ),
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
                    CategorySidebar(
                      subCategories: currentSubCategories,
                      selectedIndex: _selectedSubCategoryIndex,
                      onSelected: (index) {
                        setState(() => _selectedSubCategoryIndex = index);
                      },
                    ),
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

  Widget _buildRightGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _rentalsStream,
      initialData: _lastSnapshot,
      builder: (context, snapshot) {
        final QuerySnapshot? effectiveSnapshot = snapshot.data ?? _lastSnapshot;

        if (effectiveSnapshot == null &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF113F67)),
          );
        }

        if (effectiveSnapshot == null || effectiveSnapshot.docs.isEmpty) {
          return const Center(
            child: Text(
              'No items available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final selectedSubCategory =
            currentSubCategories[_selectedSubCategoryIndex];
        final List<Map<String, dynamic>> filteredItems = _filterItems(
          effectiveSnapshot,
          selectedSubCategory,
        );

        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              'No items in $selectedSubCategory',
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
          cacheExtent: 900,
          itemCount: filteredItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.76,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            final deal = filteredItems[index];
            return CategoryDealCard(
              deal: deal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductPage(productData: deal),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterItems(
    QuerySnapshot snapshot,
    String selectedSubCategory,
  ) {
    if (!identical(_lastSnapshot, snapshot)) {
      _lastSnapshot = snapshot;
      _filteredItemsCache.clear();
    }

    final cachedItems = _filteredItemsCache[selectedSubCategory];
    if (cachedItems != null) {
      return cachedItems;
    }

    final List<Map<String, dynamic>> filteredItems = [];

    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );
      data['id'] = doc.id;

      if (data['category'] != widget.categoryName) continue;
      if (selectedSubCategory != 'All' &&
          data['subcategory'] != selectedSubCategory) {
        continue;
      }

      filteredItems.add(data);
    }

    _filteredItemsCache[selectedSubCategory] = filteredItems;
    return filteredItems;
  }
}
