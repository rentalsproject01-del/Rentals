import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// Ensure this import path matches your project structure
import 'package:rentals/views/rent/location_picker_page.dart';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  static final TextEditingController categoryController = TextEditingController(
    text: "Fashion", // Default fallback
  );

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  final _formKey = GlobalKey<FormState>();

  // --- FIREBASE CONTROLLERS ---
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _depositController = TextEditingController();
  final _priceController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _locationController = TextEditingController(text: "Detecting...");
  final _phoneController = TextEditingController();

  String selectedDuration = 'per day';

  // --- CATEGORY AND SUBCATEGORY DATA ---
  final Map<String, List<String>> _categoriesMap = {
    'Fashion': ['Jacket', 'Dress', 'Kurta/Kurti', 'Footwear', 'Scarf', 'Other'],
    'Jewellery': [
      'Necklace',
      'Earrings',
      'Anklet',
      'Bangles/Bracelets',
      'Bridal set',
      'Other',
    ],
    'Vehicle': [
      'Cars',
      'Bike',
      'Scooter',
      'Bicycle',
      'Electric Bike/Scooter',
      'Other',
    ],
    'House': [
      'Apartment/Flat',
      'Independant Houses',
      'Rooms',
      'PG/Hostel',
      'Commerical Space',
      'Other',
    ],
    'Electronics': [
      'Speaker',
      'Camera',
      'Projector',
      'Laptop/Phone',
      'Watch',
      'Other',
    ],
    'Books': [
      'Story/Poetry',
      'Academic book',
      'Fiction Novel',
      'Non-Fictional',
      'Children’s book',
      'Other',
    ],
    'Game': [
      'VR Headset',
      'Playstation',
      'Gaming Console',
      'Game Equipment',
      'Other',
    ],
    'GYM': ['Dumbbells', 'yoga mats', 'gym equipment', 'Other'],
    'Travel': [
      'Bags',
      'Camping Tent',
      'Sleeping Bags',
      'Portable Stoves',
      'Water Bottles/Thermos',
      'Other',
    ],
    'Decore': [
      'Lights',
      'Artificial Flowers/plants',
      'theme party props',
      'Stage',
      'Mandap decore',
      'Other',
    ],
    'Furniture': [
      'Mattress',
      'Rack/Cabinet',
      'Folding Table/chairs',
      'Bench',
      'Baby Crib',
      'Other',
    ],
    'Subscription': [
      'OTT/Streaming',
      'Music',
      'Gaming',
      'Education',
      'Software/Tool',
      'Other',
    ],
    'Other': ['Other'],
  };

  late String _selectedCategory;
  late String _selectedSubcategory;

  // --- LOCATION STATE ---
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;

  // --- IMAGE UPLOAD STATE ---
  final List<File> _selectedImages = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  final PageController _pageController = PageController();
  int _currentOfferIndex = 0;
  Timer? _offerTimer;

  @override
  void initState() {
    super.initState();

    // Check navbar selection on init
    if (_categoriesMap.containsKey(RentPage.categoryController.text)) {
      _selectedCategory = RentPage.categoryController.text;
    } else {
      _selectedCategory = 'Fashion';
      RentPage.categoryController.text = 'Fashion';
    }

    // Automatically set subcategory to the first item of the selected category
    _selectedSubcategory = _categoriesMap[_selectedCategory]!.first;
    _subcategoryController.text = _selectedSubcategory;

    _startOfferTimer();
    _getCurrentLocation(); // Auto-detect location when page opens
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _pageController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _depositController.dispose();
    _priceController.dispose();
    _subcategoryController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startOfferTimer() {
    _offerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_selectedImages.isEmpty) return;

      if (_currentOfferIndex < _selectedImages.length - 1) {
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

  // --- FETCH LOCATION LOGIC ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isFetchingLocation = false;
          _locationController.text = "Location Disabled";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isFetchingLocation = false;
            _locationController.text = "Permission Denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isFetchingLocation = false;
          _locationController.text = "Permission Denied";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationController.text = "Current Location";
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
          _locationController.text = "Failed to detect";
        });
      }
    }
  }

  // --- OPEN MAP PICKER LOGIC ---
  Future<void> _openMapPicker() async {
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
        _locationController.text = "Custom Location";
      });
    }
  }

  // --- SHOW BOTTOM SHEET TO PICK IMAGES ---
  void _showImagePickerOptions() {
    FocusScope.of(context).unfocus();
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only select up to 3 images.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0D3454)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF0D3454),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- GET IMAGE FROM PHONE ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
          _currentOfferIndex = _selectedImages.length - 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  // --- UPLOAD TO FIREBASE LOGIC ---
  Future<void> _uploadAndSaveItem() async {
    FocusScope.of(context).unfocus();
    if (_isUploading) return;
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> uploadedImageUrls = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        File file = _selectedImages[i];
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('rental_images')
            .child(user.uid)
            .child(fileName);

        await storageRef.putFile(file);
        String downloadUrl = await storageRef.getDownloadURL();
        uploadedImageUrls.add(downloadUrl);
      }

      await FirebaseFirestore.instance.collection('rentals').add({
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'deposit': double.tryParse(_depositController.text) ?? 0.0,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'duration': selectedDuration,
        'category': RentPage.categoryController.text.trim(),
        'subcategory': _subcategoryController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'phoneNumber': _phoneController.text.trim(),
        'imageUrls': uploadedImageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _selectedImages.clear();
          _titleController.clear();
          _subtitleController.clear();
          _descriptionController.clear();
          _depositController.clear();
          _priceController.clear();
          _phoneController.clear();

          // Reset dropdowns to defaults
          _selectedCategory = 'Fashion';
          RentPage.categoryController.text = 'Fashion';
          _selectedSubcategory = _categoriesMap['Fashion']!.first;
          _subcategoryController.text = _selectedSubcategory;

          _currentOfferIndex = 0;
        });

        // Re-detect location for the next upload
        _getCurrentLocation();
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
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3454),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20, bottom: 30),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Image.asset(
                      'assets/icons/arrow_icon.png',
                      height: 24,
                      width: 24,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Just Rent",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
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
                  // Background White Container
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(25, 110, 25, 30),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                "Title",
                                controller: _titleController,
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                "Subtitle",
                                controller: _subtitleController,
                                isRequired: false,
                              ),
                              const SizedBox(height: 20),

                              _buildDescriptionField(
                                "Description",
                                controller: _descriptionController,
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                "Deposit (Rs)",
                                controller: _depositController,
                                isNumber: true,
                                isRequired: false,
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(child: _buildDurationDropdown()),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: _buildTextField(
                                      "Price (Rs)",
                                      controller: _priceController,
                                      isNumber: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(child: _buildCategoryDropdown()),
                                  const SizedBox(width: 15),
                                  Expanded(child: _buildSubcategoryDropdown()),
                                ],
                              ),
                              const SizedBox(height: 20),

                              _buildActionButtonField(
                                "Location",
                                _locationController.text,
                                controller: _locationController,
                                onActionTap: _openMapPicker,
                                isFetching: _isFetchingLocation,
                                buttonLabel: "Set Location",
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                "Phone Number",
                                controller: _phoneController,
                                isNumber: true,
                                hint: "e.g. 9876543210",
                              ),
                              const SizedBox(height: 40),

                              // Submit Button
                              Center(
                                child: GestureDetector(
                                  onTap: _isUploading
                                      ? null
                                      : _uploadAndSaveItem,
                                  child: Container(
                                    width: 220,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: const Color(0xFF16BCE6),
                                        width: 1.5,
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          const Color(
                                            0xFF16BCE6,
                                          ).withOpacity(0.5),
                                          const Color(
                                            0xFF00A2FF,
                                          ).withOpacity(0.5),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: _isUploading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF0D3454),
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              "Submit",
                                              style: TextStyle(
                                                color: Color(0xFF0D3454),
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating Image Carousel
                  Positioned(
                    top: 0,
                    left: 20,
                    right: 20,
                    child: _buildImageCarousel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildImageCarousel() {
    return GestureDetector(
      onTap: _selectedImages.isEmpty ? _showImagePickerOptions : null,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF16BCE6), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: _selectedImages.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 45, color: Color(0xFF16BCE6)),
                  SizedBox(height: 8),
                  Text(
                    "Add up to 3 Images",
                    style: TextStyle(
                      color: Color(0xFF16BCE6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _selectedImages.length,
                      onPageChanged: (index) =>
                          setState(() => _currentOfferIndex = index),
                      itemBuilder: (context, index) {
                        return Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                  // Page Indicators
                  if (_selectedImages.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_selectedImages.length, (
                          index,
                        ) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentOfferIndex == index
                                  ? const Color(0xFF16BCE6)
                                  : Colors.white70,
                            ),
                          );
                        }),
                      ),
                    ),
                  // Remove Image Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(_currentOfferIndex);
                          if (_currentOfferIndex >= _selectedImages.length &&
                              _currentOfferIndex > 0) {
                            _currentOfferIndex--;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Add More Images Button
                  if (_selectedImages.length < 3)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16BCE6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    bool isNumber = false,
    bool isRequired = true,
    String? hint,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              return null;
            }
          : null,
      style: const TextStyle(color: Color(0xFF0D3454)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        labelStyle: const TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(
    String label, {
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(color: Color(0xFF0D3454)),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        labelStyle: const TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedDuration,
      decoration: const InputDecoration(
        labelText: "Duration",
        labelStyle: TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
      items: ['per hour', 'per day', 'per week', 'per month'].map((
        String value,
      ) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) setState(() => selectedDuration = newValue);
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: "Category",
        labelStyle: TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
      items: _categoriesMap.keys.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCategory = newValue;
            RentPage.categoryController.text = newValue;
            _selectedSubcategory = _categoriesMap[newValue]!.first;
            _subcategoryController.text = _selectedSubcategory;
          });
        }
      },
    );
  }

  Widget _buildSubcategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSubcategory,
      decoration: const InputDecoration(
        labelText: "Subcategory",
        labelStyle: TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
      items: _categoriesMap[_selectedCategory]!.map((String subcategory) {
        return DropdownMenuItem<String>(
          value: subcategory,
          child: Text(subcategory, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(
            () => _subcategoryController.text = _selectedSubcategory = newValue,
          );
        }
      },
    );
  }

  Widget _buildActionButtonField(
    String label,
    String hint, {
    required TextEditingController controller,
    required VoidCallback onActionTap,
    bool isFetching = false,
    required String buttonLabel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildTextField(
            label,
            controller: controller,
            hint: hint,
            readOnly: true,
          ),
        ),
        const SizedBox(width: 15),
        ElevatedButton(
          onPressed: isFetching ? null : onActionTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16BCE6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
          child: isFetching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  buttonLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
