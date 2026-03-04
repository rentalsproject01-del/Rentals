import 'package:flutter/material.dart';
import 'dart:async';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  static final TextEditingController categoryController = TextEditingController(text: "Vehicle");

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  String selectedDuration = 'per day';

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
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 5, bottom: 125),
              child: Row(
                children: [
                  Image.asset('assets/icons/arrow_icon.png', height: 24, width: 24,),
                  const SizedBox(width: 4),
                  const Text(
                    "Just Rent",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
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
                child: Column(
                  children: [
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
                                        setState(() => _currentOfferIndex = index);
                                      },
                                      itemCount: _offerImages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Image.asset(_offerImages[index], fit: BoxFit.cover),
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
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _offerImages.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: index == _currentOfferIndex ? 18 : 6,
                                height: 5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: index == _currentOfferIndex
                                      ? const Color(0xFF0D3454)
                                      : const Color(0xFF00B0FF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -60),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Column(
                            children: [
                              _buildTextField("Title"),
                              _buildTextField("Subtitle"),
                              _buildTextField("Description", maxLines: 5),
                              _buildTextField("Deposite"),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField("Price")),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildDropdownField("Duration")),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField("Category", controller: RentPage.categoryController)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildTextField("Subcategory")),
                                ],
                              ),
                              _buildActionButtonField("Location", "Current"),
                              _buildActionButtonField("Number", "xxxxxxxxx"),
                              const SizedBox(height: 10),
                              Center(
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    width: 203, 
                                    height: 42, 
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: const Color(0xFF16BCE6), width: 1.5),
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          const Color(0xFF16BCE6).withOpacity(0.5),
                                          const Color(0xFF00A2FF).withOpacity(0.5),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
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
                              ),
                              const SizedBox(height: 62),
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

  // --- UPDATED HELPER WIDGETS ---

  Widget _buildTextField(String label, {int maxLines = 1, String? initialValue, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Colors.black),
        decoration: InputDecoration(
          labelText: label, // Using labelText for the floating effect
          labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w400, fontSize: 14),
          floatingLabelStyle: const TextStyle(color: Color(0xFF00B0FF), fontWeight: FontWeight.bold),
          alignLabelWithHint: true, 
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF00B0FF), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedDuration,
        style: const TextStyle(fontSize: 14, color: Colors.black),
        decoration: InputDecoration(
          labelText: label, // Added floating label here
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
          floatingLabelStyle: const TextStyle(color: Color(0xFF00B0FF), fontWeight: FontWeight.bold),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF00B0FF), width: 1.5),
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        items: <String>['per day', 'per week', 'per month'].map((String value) {
          return DropdownMenuItem<String>(
            value: value, 
            child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black))
          );
        }).toList(),
        onChanged: (val) => setState(() => selectedDuration = val!),
      ),
    );
  }

  Widget _buildActionButtonField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align with top of textfield
        children: [
          Expanded(child: _buildTextField(label, initialValue: value)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 48, // Matched height of textfield
              width: 110, 
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF16BCE6), width: 1),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF16BCE6).withOpacity(0.5),
                    const Color(0xFF00A2FF).withOpacity(0.5),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  "Change", 
                  style: TextStyle(color: Color(0xFF0D3454), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00B0FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Add Image ", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}