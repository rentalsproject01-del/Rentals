import 'package:flutter/material.dart';
import 'package:rentals/views/product/product_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _searchHints = [
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

  final PageController _offerController = PageController();
  int _currentOfferIndex = 0;
  Timer? _offerTimer;

  final List<String> _offerImages = [
    'assets/images/offer1.png',
    'assets/images/offer2.png',
    'assets/images/offer3.png',
  ];

  // --- THE FIX: Declare a persistent stream variable ---
  late Stream<QuerySnapshot> _rentalsStream;

  @override
  void initState() {
    super.initState();

    // --- THE FIX: Initialize the stream exactly once ---
    _rentalsStream = FirebaseFirestore.instance
        .collection('rentals')
        .orderBy('createdAt', descending: true)
        .snapshots();

    _startTyping();
    _startOfferTimer();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _offerTimer?.cancel();
    _offerController.dispose();
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

  void _startOfferTimer() {
    _offerTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentOfferIndex < 2) {
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
                _buildSearchBar(),
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

                    StreamBuilder<QuerySnapshot>(
                      // --- THE FIX: Use the persistent stream here ---
                      stream: _rentalsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text("No rentals available")),
                          );
                        }

                        final items = snapshot.data!.docs;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                              ),
                          itemBuilder: (context, index) {
                            final data =
                                items[index].data() as Map<String, dynamic>;

                            return _buildDealCard(context, data);
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
            Image.asset('assets/images/rentals_rlogo.png', height: 40),
            const SizedBox(width: 7),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rentals",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
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
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Image.asset("assets/icons/search_icon.png", height: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    cursorColor: const Color(0xFF113F67),
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: _displayedText,
                      hintStyle: const TextStyle(
                        color: Colors.black54,
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 25),
        Image.asset("assets/icons/cart_icon.png", height: 24, width: 24),
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
          _categoryItem("Jwellery", "assets/icons/jwellery_icon.png"),
          _categoryItem("Vehicle", "assets/icons/vehicle_icon.png"),
          _categoryItem("House", "assets/icons/house_icon.png"),
          _categoryItem("Electronics", "assets/icons/electronic_icon.png"),
          _categoryItem("Books", "assets/icons/books_icon.png"),
          _categoryItem("Game", "assets/icons/game_icon.png"),
          _categoryItem("GYM", "assets/icons/gym_icon.png"),
          _categoryItem("Travel", "assets/icons/travel_icon.png"),
          _categoryItem("Decoration", "assets/icons/decore_icon.png"),
          _categoryItem("Furniture", "assets/icons/furniture_icon.png"),
          _categoryItem("Subscription", "assets/icons/subscription_icon.png"),
          _categoryItem("Other", "assets/icons/other_icon.png"),
        ],
      ),
    );
  }

  Widget _categoryItem(String label, String assetPath) {
    return Padding(
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
    );
  }

  Widget _buildPromoBanner() {
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
              return Image.asset(_offerImages[index], fit: BoxFit.cover);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return const SizedBox();
  }

  Widget _buildDealCard(BuildContext context, Map<String, dynamic> deal) {
    String imageUrl = '';
    if (deal['imageUrls'] != null && (deal['imageUrls'] as List).isNotEmpty) {
      imageUrl = deal['imageUrls'][0];
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
          border: Border.all(color: const Color(0xFF113F67).withOpacity(0.5)),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
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
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                deal['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text("Rs ${deal['price'] ?? ''}"),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, bottom: 7, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF113F67),
        ),
      ),
    );
  }
}
