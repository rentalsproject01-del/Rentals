import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker_page.dart'; // <--- This relative import forces it to look in the exact same folder
import 'dart:async';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  static final TextEditingController categoryController = TextEditingController(
    text: "Vehicle",
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
  final _locationController = TextEditingController(
    text: "Detecting...",
  ); // Starts by showing it's loading
  final _phoneController = TextEditingController(text: "xxxxxxxxx");

  String selectedDuration = 'per day';

  // --- LOCATION STATE ---
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;

  // --- IMAGE UPLOAD STATE ---
  List<File> _selectedImages = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  final PageController _pageController = PageController();
  int _currentOfferIndex = 0;
  Timer? _offerTimer;

  @override
  void initState() {
    super.initState();
    _startOfferTimer();
    _getCurrentLocation(); // --- NEW: Auto-detect location when page opens ---
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
          _locationController.text =
              "Current Location"; // --- NEW: Updated label ---
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

  // --- NEW: OPEN MAP PICKER LOGIC ---
  Future<void> _openMapPicker() async {
    LatLng? initialPoint;
    if (_latitude != null && _longitude != null) {
      initialPoint = LatLng(_latitude!, _longitude!);
    }

    // Wait for the user to select a location and pop the screen
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(initialLocation: initialPoint),
      ),
    );

    // If they picked a location, update our state!
    if (pickedLocation != null && mounted) {
      setState(() {
        _latitude = pickedLocation.latitude;
        _longitude = pickedLocation.longitude;
        _locationController.text = "Custom Location";
      });
    }
  }

  // --- 1. SHOW BOTTOM SHEET TO PICK IMAGES ---
  void _showImagePickerOptions() {
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

  // --- 2. GET IMAGE FROM PHONE ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
          _currentOfferIndex = _selectedImages.length - 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  // --- 3. UPLOAD TO FIREBASE LOGIC ---
  Future<void> _uploadAndSaveItem() async {
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
          const SnackBar(content: Text('Item uploaded successfully!')),
        );

        setState(() {
          _selectedImages.clear();
          _titleController.clear();
          _subtitleController.clear();
          _descriptionController.clear();
          _depositController.clear();
          _priceController.clear();
          _subcategoryController.clear();
          _phoneController.text = "xxxxxxxxx";
          _currentOfferIndex = 0;
        });

        // Re-detect location for the next upload
        _getCurrentLocation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
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
              padding: const EdgeInsets.only(left: 20, top: 25, bottom: 25),
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
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Just Rent",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),

            // --- MAIN CONTENT LAYERED WITH STACK ---
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 75,
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
                        padding: const EdgeInsets.fromLTRB(20, 100, 20, 12),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                "Title",
                                controller: _titleController,
                              ),
                              _buildTextField(
                                "Subtitle",
                                controller: _subtitleController,
                              ),
                              _buildDescriptionField(
                                "Description",
                                controller: _descriptionController,
                              ),
                              _buildTextField(
                                "Deposite",
                                controller: _depositController,
                              ),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField("Duration"),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      "Price",
                                      controller: _priceController,
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      "Category",
                                      controller: RentPage.categoryController,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      "Subcategory",
                                      controller: _subcategoryController,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              // --- UPDATED: Connect map picker and change button label ---
                              _buildActionButtonField(
                                "Location",
                                "Detecting...",
                                controller: _locationController,
                                onActionTap: _openMapPicker,
                                isFetching: _isFetchingLocation,
                                buttonLabel:
                                    "Set Location", // --- NEW parameter usage ---
                              ),
                              _buildActionButtonField(
                                "Number",
                                "xxxxxxxxx",
                                controller: _phoneController,
                              ),

                              const SizedBox(height: 20),
                              Center(
                                child: GestureDetector(
                                  onTap: _isUploading
                                      ? null
                                      : _uploadAndSaveItem,
                                  child: Container(
                                    width: 200,
                                    height: 40,
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
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF0D3454),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              "Submit",
                                              style: TextStyle(
                                                color: Color(0xFF0D3454),
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
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
                  ),

                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
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
                                      setState(
                                        () => _currentOfferIndex = index,
                                      );
                                    },
                                    itemCount: _selectedImages.isEmpty
                                        ? 1
                                        : _selectedImages.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: _selectedImages.isNotEmpty
                                            ? Image.file(
                                                _selectedImages[index],
                                                fit: BoxFit.cover,
                                              )
                                            : const Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.image_not_supported,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    "No Images Selected",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
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
                        const SizedBox(height: 12),
                        if (_selectedImages.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _selectedImages.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildDescriptionField(
    String label, {
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label : ",
            style: const TextStyle(
              color: Color(0xFF0D3454),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: 5,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.blueGrey,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00B0FF),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    int maxLines = 1,
    String? initialValue,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        readOnly: label == "Location", // Prevent manual typing for location
        initialValue: controller == null ? initialValue : null,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$label : ",
                  style: const TextStyle(
                    color: Color(0xFF0D3454),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
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
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 2),
            child: Text(
              "$label : ",
              style: const TextStyle(
                color: Color(0xFF0D3454),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00B0FF), width: 0.5),
          ),
        ),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: Color(0xFF0D3454),
          size: 22,
        ),
        items: <String>['per day', 'per week', 'per month'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
          );
        }).toList(),
        onChanged: (val) => setState(() => selectedDuration = val!),
      ),
    );
  }

  // --- UPDATED: added buttonLabel with flexible width ---
  Widget _buildActionButtonField(
    String label,
    String value, {
    TextEditingController? controller,
    VoidCallback? onActionTap,
    bool isFetching = false,
    String buttonLabel = "Change",
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildTextField(
              label,
              controller: controller,
              initialValue: controller == null ? value : null,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: onActionTap ?? () {},
              child: Container(
                height: 37,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ), // Adjusts dynamically to text length
                constraints: const BoxConstraints(
                  minWidth: 85,
                ), // Matches your original width
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
                child: Center(
                  child: isFetching
                      ? const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0D3454),
                          ),
                        )
                      : Text(
                          buttonLabel, // Uses "Set Location" or "Change"
                          style: const TextStyle(
                            color: Color(0xFF0D3454),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
    return ElevatedButton.icon(
      onPressed: _showImagePickerOptions,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00B0FF),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      label: Text(
        _selectedImages.isEmpty
            ? "Add Image"
            : "Add Image (${_selectedImages.length}/3)",
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      icon: const Icon(Icons.add, color: Colors.white, size: 16),
    );
  }
}
