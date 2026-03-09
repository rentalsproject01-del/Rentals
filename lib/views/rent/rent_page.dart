import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:rentals/widgets/navbar.dart';
import 'package:rentals/views/rent/location_picker_page.dart';
import 'package:rentals/services/rental_service.dart';

class RentPage extends StatefulWidget {
  // Static controller to allow Navbar to pre-fill the category
  static final TextEditingController categoryController =
      TextEditingController();

  const RentPage({super.key});

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  // --- CONTROLLERS ---
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // --- STATE VARIABLES ---
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    priceController.dispose();
    locationController.dispose();
    // Note: RentPage.categoryController is static, so we don't dispose it here.
    super.dispose();
  }

  // --- IMAGE PICKER ---
  Future<void> _pickImages() async {
    FocusScope.of(context).unfocus();
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80, // Compress slightly for faster uploads
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      _showError("Failed to pick images: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // --- LOCATION PICKER ---
  Future<void> _pickLocation() async {
    FocusScope.of(context).unfocus();

    LatLng? initialPoint;
    if (_latitude != null && _longitude != null) {
      initialPoint = LatLng(_latitude!, _longitude!);
    }

    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(initialLocation: initialPoint),
      ),
    );

    if (pickedLocation != null && mounted) {
      setState(() {
        _latitude = pickedLocation.latitude;
        _longitude = pickedLocation.longitude;
        locationController.text = "Location Selected";
      });
    }
  }

  // --- SUBMIT LOGIC ---
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // 1. Validation
    if (titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        RentPage.categoryController.text.trim().isEmpty) {
      _showError("Please fill in all fields.");
      return;
    }

    if (_selectedImages.isEmpty) {
      _showError("Please select at least one image.");
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showError("Please select a location on the map.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Upload using RentalService
      await RentalService.uploadRental(
        title: titleController.text.trim(),
        description: descController.text.trim(),
        price: double.tryParse(priceController.text.trim()) ?? 0,
        category: RentPage.categoryController.text.trim(),
        images: _selectedImages,
        latitude: _latitude!,
        longitude: _longitude!,
      );

      // 3. Success Behavior
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Item listed successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to Navbar and clear the stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Navbar()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF113F67),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // --- HEADER SECTION ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      'List an Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // --- FORM BODY ---
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(25, 35, 25, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images Section
                        const Text(
                          "Photos",
                          style: TextStyle(
                            color: Color(0xFF113F67),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildImageSelector(),
                        const SizedBox(height: 25),

                        // Title
                        _buildInputField(
                          label: 'Title',
                          hint: 'e.g., Sony Camera',
                          icon: Icons.title,
                          controller: titleController,
                        ),
                        const SizedBox(height: 25),

                        // Category (Pre-filled by Navbar)
                        _buildInputField(
                          label: 'Category',
                          hint: 'e.g., Electronics',
                          icon: Icons.category,
                          controller: RentPage.categoryController,
                        ),
                        const SizedBox(height: 25),

                        // Price
                        _buildInputField(
                          label: 'Price per day (Rs.)',
                          hint: 'e.g., 500',
                          icon: Icons.currency_rupee,
                          controller: priceController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 25),

                        // Location
                        _buildInputField(
                          label: 'Pickup Location',
                          hint: 'Tap to select on map',
                          icon: Icons.location_on,
                          controller: locationController,
                          readOnly: true,
                          onTap: _pickLocation,
                        ),
                        const SizedBox(height: 25),

                        // Description
                        _buildInputField(
                          label: 'Description',
                          hint: 'Provide details about the item...',
                          icon: Icons.description,
                          controller: descController,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 45),

                        // Submit Button
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildImageSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFF16BCE6),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Color(0xFF16BCE6)),
                  SizedBox(height: 4),
                  Text(
                    "Add",
                    style: TextStyle(color: Color(0xFF16BCE6), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          ..._selectedImages.asMap().entries.map((entry) {
            int index = entry.key;
            File image = entry.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: FileImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: -5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF113F67)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF113F67),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Color(0xFF113F67)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF6F7172), fontSize: 13),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF113F67), width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF16BCE6), Color(0xFF00A2FF)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'List Item Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
