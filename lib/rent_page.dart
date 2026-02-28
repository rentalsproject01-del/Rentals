import 'package:flutter/material.dart';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  String selectedDuration = 'per day';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3454), // Exact Dark Navy from image
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Custom Header ---
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 5, bottom: 25),
              child: Row(
                children: [
                  Image.asset("assets/icons/arrow_icon.png", height: 24, width: 24),
                  const SizedBox(width: 5),
                  const Text(
                    "Just Rent",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      // fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // --- Main Form Card ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Image Section ---
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              height: 170,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: const DecorationImage(
                                  image: NetworkImage('https://images.pexels.com/photos/10312002/pexels-photo-10312002.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'),
                                  fit: BoxFit.cover,
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
                      const SizedBox(height: 10),
                      
                      // --- Indicators ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(const Color(0xFF0D3454), width: 18),
                          _buildDot(const Color(0xFF00B0FF)),
                          _buildDot(const Color(0xFF00B0FF)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- Input Fields ---
                      _buildTextField("Title :"),
                      _buildTextField("Subtitle :"),
                      _buildTextField("Description :", maxLines: 5),
                      _buildTextField("Subtitle :"),

                      // --- Price and Duration Row ---
                      Row(
                        children: [
                          Expanded(child: _buildTextField("Ret/Price :")),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDropdownField("Duration :")),
                        ],
                      ),

                      // --- Category and Subcategory Row ---
                      Row(
                        children: [
                          Expanded(child: _buildTextField("Category :", initialValue: "Vehicle")),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField("Subcategory :")),
                        ],
                      ),

                      // --- Location with Change Button ---
                      _buildActionButtonField("Location :", "Current"),

                      // --- Number with Change Button ---
                      _buildActionButtonField("Number :", "xxxxxxxxx"),

                      const SizedBox(height: 25),

                      // --- Submit Button ---
                      Center(
                        child: SizedBox(
                          width: 210,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF81D4FA), // Light blue from image
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
                      const SizedBox(height: 120), // Padding for the Navbar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildDot(Color color, {double width = 7}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 6,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text("Add Image ", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}