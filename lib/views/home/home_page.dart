import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/views/search/search_page.dart';
import 'package:rentals/category_page.dart';
import 'package:rentals/services/rental_service.dart';
import 'package:rentals/services/favorites_service.dart';
import 'package:rentals/services/user_service.dart';

// Kept for backward compatibility if any unedited file imports it.
List<Map<String, dynamic>> globalLikedItems = [];

class HomePage extends StatefulWidget {
  final VoidCallback onMapTap;
  final VoidCallback onNearMeTap;
  final Function(String) onCategorySelected;

  const HomePage({
    super.key,
    required this.onMapTap,
    required this.onNearMeTap,
    required this.onCategorySelected,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _offerController = PageController();
  int _currentOfferIndex = 0;
  Timer? _offerTimer;

  String _userName = "User";
  String _profileImageUrl = "";
  bool _isLoadingUser = true;

  final List<String> _offerImages = const [
    'assets/images/offer1.png',
    'assets/images/offer2.png',
    'assets/images/offer3.png',
  ];

  @override
  void initState() {
    super.initState();
    _startOfferTimer();
    _fetchUserData();
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _offerController.dispose();
    super.dispose();
  }

  void _startOfferTimer() {
    _offerTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_offerImages.isEmpty) return;

      if (_currentOfferIndex < _offerImages.length - 1) {
        _currentOfferIndex++;
      } else {
        _currentOfferIndex = 0;
      }

      if (_offerController.hasClients) {
        _offerController.animateToPage(
          _currentOfferIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await UserService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userName = userData?['name'] ?? "User";
          _profileImageUrl = userData?['profileImageUrl'] ?? "";
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 5),
            child: Column(
              children: [
                _buildTopHeader(),
                const SizedBox(height: 12),
                AnimatedSearchBar(onTap: _openSearchScreen),
                const SizedBox(height: 12),
                _buildCategoryList(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Your Rent.., Your Way..."),

                    SizedBox(
                      height: 290,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildNearMeBanner(),
                          _buildPromoBanner(),
                          _buildPageIndicator(),
                        ],
                      ),
                    ),

                    _buildSectionTitle("Top Deals"),

                    StreamBuilder<dynamic>(
                      stream: RentalService.getAllRentalsWithOwnerNames(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF113F67),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                "No items available yet",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        List<Map<String, dynamic>> items = [];

                        if (snapshot.data is QuerySnapshot) {
                          final docs = (snapshot.data as QuerySnapshot).docs;
                          if (docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  "No items available yet",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }
                          for (var doc in docs) {
                            final data = Map<String, dynamic>.from(
                              doc.data() as Map<String, dynamic>,
                            );
                            data['id'] = doc.id;
                            items.add(data);
                          }
                        } else if (snapshot.data is List) {
                          final list = snapshot.data as List;
                          if (list.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  "No items available yet",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }
                          for (var item in list) {
                            items.add(Map<String, dynamic>.from(item as Map));
                          }
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          cacheExtent: 800,
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                              ),
                          itemBuilder: (context, index) {
                            return _buildDealCard(context, items[index]);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: const Color(0xFF16BCE6), width: 1.5),
              ),
              child: ClipOval(
                child: _profileImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _profileImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 20,
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.grey, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoadingUser
                    ? const SizedBox(
                        height: 10,
                        width: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                const Text(
                  "Just Rent",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        Image.asset(
          "assets/icons/notification_icon.png",
          height: 24,
          width: 24,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.notifications_none, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 77,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryItem("Fashion", "assets/icons/fashion_icon.png"),
          _categoryItem("Jewellery", "assets/icons/jwellery_icon.png"),
          _categoryItem("Vehicle", "assets/icons/vehicle_icon.png"),
          _categoryItem("House", "assets/icons/house_icon.png"),
          _categoryItem("Electronics", "assets/icons/electronic_icon.png"),
          _categoryItem("Books", "assets/icons/books_icon.png"),
          _categoryItem("Game", "assets/icons/game_icon.png"),
          _categoryItem("GYM", "assets/icons/gym_icon.png"),
          _categoryItem("Travel", "assets/icons/travel_icon.png"),
          _categoryItem("Decore", "assets/icons/decore_icon.png"),
          _categoryItem("Furniture", "assets/icons/furniture_icon.png"),
          _categoryItem("Subscription", "assets/icons/subscription_icon.png"),
          _categoryItem("Other", "assets/icons/other_icon.png"),
        ],
      ),
    );
  }

  Widget _categoryItem(String label, String assetPath) {
    return GestureDetector(
      onTap: () {
        widget.onCategorySelected(label);
        if (label != 'All') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryPage(categoryName: label),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A2FF), Color(0xFF16BCE6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Image.asset(
                  assetPath,
                  height: 28,
                  width: 28,
                  color: Colors.white,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.category, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearMeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 82,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(15),
        image: const DecorationImage(
          image: AssetImage('assets/images/nearme_googlemap.png'),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onNearMeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF113F67),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/icons/nearme_icon.png",
                          height: 18,
                          width: 18,
                          color: const Color(0xFF113F67),
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.near_me,
                            color: Color(0xFF113F67),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Near Me",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF113F67),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: widget.onMapTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF217DCD), Color(0xFF113F67)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text(
                      "View On Maps",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Image.asset(
                      "assets/icons/map_icon.png",
                      height: 14,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.map, color: Colors.white, size: 14),
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

  Widget _buildPromoBanner() {
    if (_offerImages.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: PageView.builder(
            controller: _offerController,
            itemCount: _offerImages.length,
            itemBuilder: (context, index) {
              return Image.asset(
                _offerImages[index],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.local_offer,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    if (_offerImages.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 290,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _offerImages.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == _currentOfferIndex ? 20 : 6,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: index == _currentOfferIndex
                  ? const Color(0xFF113F67)
                  : const Color(0xFF16BCE6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, Map<String, dynamic> deal) {
    String imageUrl = '';

    if (deal['imageUrls'] != null) {
      if (deal['imageUrls'] is List) {
        final list = (deal['imageUrls'] as List)
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .toList();
        if (list.isNotEmpty) {
          imageUrl = list[0].toString();
        }
      } else if (deal['imageUrls'] is String &&
          deal['imageUrls'].toString().trim().isNotEmpty) {
        imageUrl = deal['imageUrls'].toString().trim();
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
              color: Colors.black.withOpacity(0.05),
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
                        Text(
                          "Rs. ${deal['price'] ?? '0'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Color(0xFF113F67),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, bottom: 12, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF113F67),
        ),
      ),
    );
  }
}

class AnimatedSearchBar extends StatefulWidget {
  final VoidCallback? onTap;

  const AnimatedSearchBar({super.key, this.onTap});

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  final List<String> _searchHints = const [
    "Camera",
    "Speaker",
    "Book",
    "Jacket",
    "Sneaker",
    "Necklace",
    "PS5",
    "Subscription",
  ];

  int _currentHintIndex = 0;
  String _displayedText = "";
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    const typingSpeed = Duration(milliseconds: 150);
    const deleteSpeed = Duration(milliseconds: 100);
    const pauseDuration = Duration(seconds: 2);

    _typingTimer = Timer.periodic(_isDeleting ? deleteSpeed : typingSpeed, (
      timer,
    ) {
      if (!mounted) return;
      if (_searchHints.isEmpty) return;

      final currentFullText = _searchHints[_currentHintIndex];

      setState(() {
        if (!_isDeleting) {
          if (_charIndex < currentFullText.length) {
            _charIndex++;
            _displayedText = currentFullText.substring(0, _charIndex);
          } else {
            _isDeleting = true;
            _typingTimer?.cancel();
            Future.delayed(pauseDuration, _startTyping);
          }
        } else {
          if (_charIndex > 0) {
            _charIndex--;
            _displayedText = currentFullText.substring(0, _charIndex);
          } else {
            _isDeleting = false;
            _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
            _typingTimer?.cancel();
            Future.delayed(const Duration(milliseconds: 500), _startTyping);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/search_icon.png",
                    height: 20,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF113F67),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayedText,
                      style: const TextStyle(
                        color: Color(0xFF113F67),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Image.asset(
          "assets/icons/cart_icon.png",
          height: 24,
          width: 24,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
        ),
      ],
    );
  }
}

class AnimatedLikeButton extends StatelessWidget {
  final Map<String, dynamic> deal;
  const AnimatedLikeButton({super.key, required this.deal});

  @override
  Widget build(BuildContext context) {
    String rentalId = FavoritesService.getRentalId(deal);

    return StreamBuilder<bool>(
      stream: FavoritesService.isFavoriteStream(rentalId),
      builder: (context, snapshot) {
        bool isLiked = snapshot.data ?? false;

        return GestureDetector(
          onTap: () async {
            if (rentalId.isEmpty || rentalId == 'unknown_id') return;
            try {
              await FavoritesService.toggleFavorite(deal);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to update favorites.")),
                );
              }
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Image.asset(
              isLiked
                  ? "assets/icons/like_icon3.png"
                  : "assets/icons/like_icon.png",
              key: ValueKey<bool>(isLiked),
              height: 14,
              width: 14,
              errorBuilder: (c, e, s) => Icon(
                isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                size: 14,
                color: isLiked ? Colors.red : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
