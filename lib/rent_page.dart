import 'package:flutter/material.dart';
import 'dart:async';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  String selectedDuration = 'per day';

  // --- OFFER BANNER LOGIC ---
  final PageController _pageController = PageController();
  int _currentOfferIndex = 0;
  Timer? _offerTimer;
  final List<String> _offerImages = [
    'assets/images/jacket_img.png',
    'assets/images/jacket_img.png',
    'assets/images/jacket_img.png',
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
      backgroundColor: const Color(0xFF0D3454),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- FIXED SECTION: Header ---
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 5, bottom: 125),
              child: Row(
                children: [
                  Image.asset("assets/icons/arrow_icon.png", height: 24, width: 24),
                  const SizedBox(width: 5),
                  const Text(
                    "Just Rent",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            // --- MAIN CONTAINER ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // --- FIXED SECTION: Image & Indicators ---
                    Transform.translate(
                      offset: const Offset(0, -90),
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SizedBox(
                                  height: 150,
                                  width: 300,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: PageView.builder(
                                      controller: _pageController,
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
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: _buildAddImageButton(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Indicators remain fixed above the scrollable area
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _offerImages.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: index == _currentOfferIndex ? 24 : 6,
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
                        ],
                      ),
                    ),

                    // --- SCROLLABLE SECTION: Form Fields (From Code 2) ---
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -66), // Adjust to follow the indicator spacing
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildTextField("Title :"),
                              _buildTextField("Subtitle :"),
                              _buildTextField("Description :", maxLines: 5),
                              _buildTextField("Subtitle :"),

                              Row(
                                children: [
                                  Expanded(child: _buildTextField("Price :")),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildDropdownField("Duration :")),
                                ],
                              ),

                              Row(
                                children: [
                                  Expanded(child: _buildTextField("Category :", initialValue: "Vehicle")),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildTextField("Subcategory :")),
                                ],
                              ),

                              _buildActionButtonField("Location :", "Current"),
                              _buildActionButtonField("Number :", "xxxxxxxxx"),

                              // const SizedBox(height: 5),

                              Center(
                                child: SizedBox(
                                  width: 210,
                                  height: 45,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF81D4FA),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Submit",
                                      style: TextStyle(
                                        color: Color(0xFF0D3454),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40), // Bottom breathing room
                            ],
                          ),
                        ),
                      ),
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

  // --- Helper Widgets from Code 2 ---

  Widget _buildTextField(String label, {int maxLines = 1, String? initialValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w400, fontSize: 14),
          alignLabelWithHint: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF00B0FF)),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedDuration,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            items: <String>['per day', 'per week', 'per month'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
            }).toList(),
            onChanged: (val) => setState(() => selectedDuration = val!),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtonField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(label, initialValue: value),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            width: 135,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF81D4FA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text("Change", style: TextStyle(color: Color(0xFF0D3454), fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00B0FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Add Image ", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}