import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:rentals/services/google_maps_location_service.dart';
import 'package:rentals/views/rent/location_picker_page.dart';
import 'package:rentals/views/rent/rent_form.dart';
import 'package:rentals/views/rent/rent_image_picker.dart';
import 'package:rentals/views/rent/rent_category_selector.dart';
import 'package:rentals/views/rent/rent_submit_service.dart';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  static final TextEditingController categoryController = TextEditingController(
    text: "Fashion",
  );

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<RentImagePickerState> _imagePickerKey =
      GlobalKey<RentImagePickerState>();

  // --- FIREBASE CONTROLLERS ---
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _depositController = TextEditingController();
  final _priceController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _locationController = TextEditingController(text: "Detecting...");
  final _phoneController = TextEditingController(text: "xxxxxxxxx");
  final _emailController = TextEditingController(text: "xyz@gmail.com");

  String _selectedDuration = 'Per Day';
  List<File> _selectedImages = [];
  bool _isUploadInFlight = false;

  // --- LOCATION STATE ---
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;

  // --- DESIGN COLORS ---
  final Color primaryDarkBlue = const Color(0xFF113F67);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _depositController.dispose();
    _priceController.dispose();
    _subcategoryController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- FETCH LOCATION LOGIC ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      final selection =
          await GoogleMapsLocationService.getCurrentLocationSelection();

      if (mounted) {
        setState(() {
          _latitude = selection.latitude;
          _longitude = selection.longitude;
          _locationController.text = selection.location;
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
          _locationController.text = "Tap to choose location";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  // --- OPEN MAP PICKER LOGIC ---
  Future<void> _openMapPicker() async {
    LatLng? initialPoint;
    if (_latitude != null && _longitude != null) {
      initialPoint = LatLng(_latitude!, _longitude!);
    }

    final LocationSelectionData? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialLocation: initialPoint,
          initialLocationLabel: _latitude != null && _longitude != null
              ? _locationController.text.trim()
              : null,
        ),
      ),
    );

    if (pickedLocation != null && mounted) {
      setState(() {
        _latitude = pickedLocation.latitude;
        _longitude = pickedLocation.longitude;
        _locationController.text = pickedLocation.location;
      });
    }
  }

  Future<void> _showTopSuccessBanner(String message) async {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topInset + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF113F67),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF16BCE6),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    await Future.delayed(const Duration(milliseconds: 1100));
    overlayEntry.remove();
  }

  // --- UPLOAD & SAVE LOGIC ---
  Future<void> _uploadAndSaveItem() async {
    if (_isUploadInFlight) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 image')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location or set one manually.'),
        ),
      );
      return;
    }

    _isUploadInFlight = true;

    try {
      await RentSubmitService.uploadRental(
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        description: _descriptionController.text.trim(),
        deposit: double.tryParse(_depositController.text) ?? 0.0,
        price: double.tryParse(_priceController.text) ?? 0.0,
        duration: _selectedDuration,
        category: RentPage.categoryController.text.trim(),
        subcategory: _subcategoryController.text.trim(),
        location: _locationController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        images: _selectedImages,
      );

      if (!mounted) return;
      await _showTopSuccessBanner('Item uploaded successfully!');

      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _isUploadInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20, bottom: 45),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: Image.asset(
                      'assets/icons/arrow_icon.png',
                      height: 24,
                      width: 24,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Just Rent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Asap',
                    ),
                  ),
                ],
              ),
            ),

            // --- MAIN CONTENT LAYERED WITH STACK ---
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 60,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 145, 20, 30),
                        child: RentForm(
                          formKey: _formKey,
                          titleController: _titleController,
                          subtitleController: _subtitleController,
                          descriptionController: _descriptionController,
                          depositController: _depositController,
                          priceController: _priceController,
                          locationController: _locationController,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          selectedDuration: _selectedDuration,
                          onDurationChanged: (val) =>
                              setState(() => _selectedDuration = val),
                          isFetchingLocation: _isFetchingLocation,
                          onLocationTap: _openMapPicker,
                          onSubmit: _uploadAndSaveItem,
                          categorySelector: RentCategorySelector(
                            categoryController: RentPage.categoryController,
                            subcategoryController: _subcategoryController,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating Image Carousel
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: RentImagePicker(
                      key: _imagePickerKey,
                      onImagesChanged: (files) =>
                          _selectedImages = List<File>.from(files),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
