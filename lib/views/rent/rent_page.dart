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
              padding: const EdgeInsets.only(left: 20, top: 25, bottom: 150),
              child: Row(
                children: [
                  Image.asset('assets/icons/arrow_icon.png', height: 24, width: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.arrow_back, color: Colors.white)),
                  const SizedBox(width: 4),
                  const Text(
                    "Just Rent",
                    style: TextStyle(color: Colors.white, fontSize: 20),
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
                                          child: Image.asset(_offerImages[index], fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 50, color: Colors.grey)),
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
                        offset: const Offset(0, -67),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField("Title"),
                              _buildTextField("Subtitle"), 
                              _buildDescriptionField("Description"),  
                              _buildTextField("Deposite"),
                              
                              Row(
                                children: [
                                  Expanded(child: _buildDropdownField("Duration")),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildTextField("Price")),
                                ],
                              ),
                              
                              
                              Row(
                                children: [
                                  Expanded(child: _buildTextField("Category", controller: RentPage.categoryController)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildTextField("Subcategory")),
                                ],
                              ),
                              
                              const SizedBox(height: 15),
                              
                              _buildActionButtonField("Location", "Current"),
                              _buildActionButtonField("Number", "xxxxxxxxx"),
                              
                              const SizedBox(height: 20),
                              Center(
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    width: 200, 
                                    height: 40, 
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

  // --- WIDGETS ---

  Widget _buildDescriptionField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label : ",
            style: const TextStyle(color: Color(0xFF0D3454), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          TextFormField(
            maxLines: 5, // Reduced maxLines for smaller size
            style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true, // Makes the field more compact
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00B0FF), width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {int maxLines = 1, String? initialValue, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true, // Reduced vertical size
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("$label : ", style: const TextStyle(color: Color(0xFF0D3454), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00B0FF), width: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: selectedDuration,
        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 2),
            child: Text("$label : ", style: const TextStyle(color: Color(0xFF0D3454), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00B0FF), width: 0.5),
          ),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0D3454), size: 22),
        items: <String>['per day', 'per week', 'per month'].map((String value) {
          return DropdownMenuItem<String>(
            value: value, 
            child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.blueGrey))
          );
        }).toList(),
        onChanged: (val) => setState(() => selectedDuration = val!),
      ),
    );
  }

  Widget _buildActionButtonField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildTextField(label, initialValue: value)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 10), // Matches TextField bottom padding
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 37, // Adjusted height to match smaller textfield
                width: 85, 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
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
                    style: TextStyle(color: Color(0xFF0D3454), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00B0FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add Image ", style: TextStyle(color: Colors.white, fontSize: 12)),
          const Icon(Icons.add, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}