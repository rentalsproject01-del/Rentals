import 'package:flutter/material.dart';
import 'package:rentals/product_page.dart';
import 'dart:async';

// 1. DATA MODEL FOR DYNAMIC LIST
class RentalDeal {
  final String title;
  final String subTitle;
  final String rating;
  final String imagePath;
  final String price;

  RentalDeal({
    required this.title,
    required this.subTitle,
    required this.rating,
    required this.imagePath,
    required this.price,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- TYPING ANIMATION LOGIC ---
  final List<String> _searchHints = ["Camera", "Speaker", "Book", "Jacket", "Sneaker", "Necklace", "PS5", "Subscription"];
  int _currentHintIndex = 0;
  String _displayedText = "";
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _typingTimer;

  // --- OFFER BANNER LOGIC ---
  final PageController _offerController = PageController();
  int _currentOfferIndex = 0;
  Timer? _offerTimer;
  final List<String> _offerImages = [
    'assets/images/offer1.png',
    'assets/images/offer2.png',
    'assets/images/offer3.png',
  ];

  @override
  void initState() {
    super.initState();
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

    _typingTimer = Timer.periodic(_isDeleting ? deleteSpeed : typingSpeed, (timer) {
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

  // 2. DYNAMIC LIST DATA
  final List<RentalDeal> topDeals = [
    RentalDeal(
      title: "Jbl Speaker",
      subTitle: "Portable",
      rating: "4.3",
      imagePath: "assets/images/speaker_img.png",
      price: "Rs.",
    ),
    RentalDeal(
      title: "Wireless Controller",
      subTitle: "White",
      rating: "4.7",
      imagePath: "assets/images/wireless_controller.png",
      price: "Rs.",
    ),
    RentalDeal(
      title: "Hooked",
      subTitle: "Book",
      rating: "4.3",
      imagePath: "assets/images/book_img.png",
      price: "Rs.",
    ),
    RentalDeal(
      title: "Jacket",
      subTitle: "Fashion",
      rating: "4.7",
      imagePath: "assets/images/jacket_img.png",
      price: "Rs.",
    ),
  ];

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
                      height: 290, // Increased height slightly to accommodate the indicator
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: topDeals.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75, // CHANGED: Decreased from 0.9 to 0.75 to fix overflow
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                        ),
                        itemBuilder: (context, index) {
                          return _buildDealCard(topDeals[index]);
                        },
                      ),
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
                Text("Rentals", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                Text("Just Rent", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
        Image.asset("assets/icons/notification_icon.png", height: 24, width: 24),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
                      hintStyle: const TextStyle(color: Colors.black54, fontSize: 18),
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
        Image.asset("assets/icons/cart_icon.png", height: 24, width: 24)
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            height: 45, width: 45,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A2FF), Color(0xFF16BCE6)],
                begin: Alignment.topCenter, 
                end: Alignment.bottomCenter
              ),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Center(child: Image.asset(assetPath, height: 28, width: 28, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNearMeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
                Row(
                  children: [
                    Image.asset("assets/icons/nearme_icon.png", height: 20, width: 20, color: const Color(0xFF113F67)),
                    const SizedBox(width: 5),
                    const Text("Near Me", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF113F67))),
                  ],
                ),
                const SizedBox(height: 5),
                const Text("Govardhan Colony", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const Text("1.3 Km | Nearest", style: TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF217DCD), Color(0xFF113F67)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text("View On Maps", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Image.asset("assets/icons/map_icon.png", height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
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
            onPageChanged: (index) {
              setState(() {
                _currentOfferIndex = index;
              });
            },
            itemCount: _offerImages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_offerImages[index]),
                    fit: BoxFit.cover,
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

  Widget _buildDealCard(RentalDeal deal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF113F67).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      deal.imagePath,
                      fit: BoxFit.cover,
                      height: 100,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 7, 
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF113F67).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(deal.rating, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          const SizedBox(width: 2),
                          Image.asset("assets/icons/star_icon.png", height: 12),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          // Expanded ensures that the text takes up the remaining space and doesn't overflow
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Keeps price at bottom
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF113F67)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(deal.subTitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(deal.price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF113F67))),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProductPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          width: 50,
                          height: 25,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF113F67)),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Image.asset("assets/icons/rent_icon.png", ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, bottom: 7, top: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF113F67))),
    );
  }
}