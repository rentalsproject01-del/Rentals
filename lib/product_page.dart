import 'package:flutter/material.dart';
import 'dart:async';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // --- CAROUSEL LOGIC ---
  final PageController _pageController = PageController();
  int _currentOfferIndex = 0;
  Timer? _offerTimer;
  
  final List<String> _offerImages = [
    'assets/images/speaker_img.png', 
    'assets/images/speaker_img.png',
    'assets/images/speaker_img.png',
  ];

  @override
  void initState() {
    super.initState();
    _startOfferTimer();
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startOfferTimer() {
    _offerTimer = Timer.periodic(const Duration(seconds: 9), (Timer timer) {
      if (_currentOfferIndex < _offerImages.length - 1) {
        _currentOfferIndex++;
      } else {
        _currentOfferIndex = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentOfferIndex,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67), // Dark blue background
      body: Stack(
        children: [
          // 1. Background White Panel
          Column(
            children: [
              const SizedBox(height: 224),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Main Scrollable Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 30),
                  _buildImageCarousel(),
                  const SizedBox(height: 12),
                  _buildPageIndicators(),
                  const SizedBox(height: 15),
                  _buildProductInfo(),
                  const SizedBox(height: 15),
                  _buildSellerSection(),
                  const SizedBox(height: 15),
                  _buildPricingSection(),
                  const SizedBox(height: 15),
                  _buildDescription(),
                  const SizedBox(height: 25),
                  _buildFooterAction(),
                  const SizedBox(height: 30), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT WIDGETS ---

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset('assets/icons/arrow_icon.png', height: 24, width: 24),
              ),
              const SizedBox(width: 7),
              const Text(
                'Product',
                style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Asap'),
              ),
            ],
          ),
          Container(
            width: 25,
            height: 25,
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF16BCE6), Color(0xFF00A2FF)]),
            ),
            child: Image.asset('assets/icons/like_icon.png', height: 18, width: 18,),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Center(
      child: SizedBox(
        height: 150,
        width: 300,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentOfferIndex = index),
            itemCount: _offerImages.length,
            itemBuilder: (context, index) {
              return Image.asset(_offerImages[index], fit: BoxFit.cover);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _offerImages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: index == _currentOfferIndex ? 18 : 6,
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: index == _currentOfferIndex ? const Color(0xFF113F67) : const Color(0xFF00B0FF),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jbl Speaker', style: TextStyle(color: Color(0xFF113F67), fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Days One')),
              Text('Portable', style: TextStyle(color: Color(0xFF6F7172), fontSize: 16)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF113F67),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                const Text('3.7 ', style: TextStyle(color: Colors.white, fontSize: 12)),
                Image.asset('assets/icons/star_icon.png', height: 14, width: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seller', style: TextStyle(color: Color(0xFF113F67), fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF113F67).withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 22, backgroundImage: AssetImage('assets/images/profile_img2.png')),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Steve\nHarrington', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Days One')),
                ),
                _buildActionIcon(Image.asset('assets/icons/map_icon2.png',)),
                const SizedBox(width: 10),
                _buildActionIcon(Image.asset('assets/icons/chat_icon2.png',)),
                const SizedBox(width: 10),
                _buildActionIcon(Image.asset('assets/icons/call_icon.png',)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'Rs. 500 ', style: TextStyle(color: Color(0xFF113F67), fontSize: 24, fontWeight: FontWeight.bold)),
                TextSpan(text: 'per week', style: TextStyle(color: Color(0xFF113F67), fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Text('Deposit - 000 Rs.', style: TextStyle(color: Colors.black, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description -', style: TextStyle(color: Color(0xFF113F67), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            'The JBL portable bluetooth colourful speaker delivers clear, powerful sound in a compact design.\nIt connects easily to your phone with Bluetooth.\nThe bright colours give it a fun and stylish look...',
            style: TextStyle(color: const Color(0xFF6F7172).withOpacity(0.8), fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF113F67).withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Price\nRs.', style: TextStyle(color: Colors.white, fontSize: 14)),
            Row(
              children: [
                const Text('Add My Rent', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Image.asset('assets/icons/MyRent_icon.png', height: 20, width: 20, color: Colors.white),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildActionIcon(Widget iconWidget) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF16BCE6), Color(0xFF00A2FF)]),
      ),
      child: iconWidget,
    );
  }
}