// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';

import 'package:rentals/widgets/navbar.dart';
import 'package:rentals/views/rent/location_picker_page.dart';
import 'package:rentals/services/user_service.dart';
import 'package:rentals/core/utils/validators.dart';

class AccountSetupPage extends StatefulWidget {
  const AccountSetupPage({super.key});

  @override
  State<AccountSetupPage> createState() => _AccountSetupPageState();
}

class _AccountSetupPageState extends State<AccountSetupPage> {
  // --- CONSTANTS ---
  static const String DEFAULT_PROFILE_IMAGE_URL =
      'https://firebasestorage.googleapis.com/v0/b/rentals-f9de4.appspot.com/o/default_avatar.png?alt=media';

  // --- CONTROLLERS ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // --- STATE VARIABLES ---
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if data exists in FirebaseAuth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null) nameController.text = user.displayName!;
      if (user.email != null) emailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    locationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // --- SHOW IMAGE PICKER OPTIONS (BOTTOM SHEET) ---
  void _showImagePickerOptions() {
    FocusScope.of(context).unfocus(); // Dismiss keyboard

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF113F67)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF113F67),
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

  // --- PICK IMAGE ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError("Failed to pick image: $e");
    }
  }

  // --- PICK LOCATION VIA MAP ---
  Future<void> _pickLocation() async {
    FocusScope.of(context).unfocus(); // Dismiss keyboard

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
    FocusScope.of(context).unfocus(); // Drop keyboard safely

    // 1. Strict Validation Check
    if (nameController.text.trim().isEmpty) {
      _showError("Name is required");
      return;
    }

    final phone = phoneController.text.trim();
    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showError("Please select your location on the map");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Get Current User
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError("Fatal Error: No authenticated user found.");
        setState(() => _isLoading = false);
        return;
      }

      String imageUrl = DEFAULT_PROFILE_IMAGE_URL;

      // 3. Upload Image if selected
      if (_imageFile != null) {
        Reference ref = FirebaseStorage.instance.ref().child(
          'profile_images/${user.uid}.jpg',
        );

        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      // 4. Save to Firestore using UserService
      await UserService.createUserProfile(
        name: nameController.text.trim(),
        email: user.email ?? "",
        phone: phone,
        latitude: _latitude!,
        longitude: _longitude!,
        profileImageUrl: imageUrl,
      );

      // Optional: Update Firebase Auth Display Name
      await user.updateDisplayName(nameController.text.trim());

      // 5. Navigate to Main App
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Navbar()),
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
    // Prevent back navigation entirely during setup
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFF113F67),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // --- HEADER SECTION ---
                const Padding(
                  padding: EdgeInsets.fromLTRB(25, 20, 25, 20),
                  child: Row(
                    children: [
                      Text(
                        'Account Setup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- MAIN BODY SECTION ---
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // White Background Container
                      Container(
                        margin: const EdgeInsets.only(top: 55),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(25, 75, 25, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputField(
                                label: 'Name',
                                hint: 'Enter Your Name',
                                iconAsset: 'assets/icons/call_icon.png',
                                controller: nameController,
                              ),
                              const SizedBox(height: 25),

                              _buildInputField(
                                label: 'Email address',
                                hint: 'Enter your email',
                                iconAsset: 'assets/icons/email_icon.png',
                                controller: emailController,
                                enabled: false,
                              ),
                              const SizedBox(height: 25),

                              // Location Field - Taps open Map Picker
                              _buildInputField(
                                label: 'Location',
                                hint: 'Tap to select location',
                                iconAsset: 'assets/icons/location_icon.png',
                                controller: locationController,
                                readOnly: true,
                                onTap: _pickLocation,
                              ),
                              const SizedBox(height: 25),

                              _buildPhoneField(controller: phoneController),

                              const SizedBox(height: 45),
                              _buildSubmitButton(),
                            ],
                          ),
                        ),
                      ),

                      // Floating Profile Image
                      Align(
                        alignment: Alignment.topCenter,
                        child: _buildProfileImageSelector(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildProfileImageSelector() {
    // Wrapped entire stack in GestureDetector to guarantee tap registers
    return GestureDetector(
      onTap: _showImagePickerOptions,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFF16BCE6), width: 2.5),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFF0F0F0),
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : null,
              child: _imageFile == null
                  ? const Icon(Icons.person, size: 50, color: Color(0xFF113F67))
                  : null,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 5, right: 5),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16BCE6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required String iconAsset,
    required TextEditingController controller,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              iconAsset,
              height: 18,
              color: const Color(0xFF113F67),
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF113F67),
              ),
            ),
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
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            color: enabled ? const Color(0xFF113F67) : Colors.grey,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF6F7172), fontSize: 13),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF113F67), width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
            ),
            disabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField({required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/icons/person_icon.png',
              height: 18,
              color: const Color(0xFF113F67),
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.phone, size: 18, color: Color(0xFF113F67)),
            ),
            const SizedBox(width: 8),
            const Text(
              'Phone number',
              style: TextStyle(
                color: Color(0xFF113F67),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text(
              '+91 ',
              style: TextStyle(
                color: Color(0xFF6F7172),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: 10, // Enforces UI max length
                style: const TextStyle(color: Color(0xFF113F67)),
                decoration: const InputDecoration(
                  hintText: 'Enter your 10 digit Phone no',
                  counterText: "", // Hides the counter below the field
                  hintStyle: TextStyle(color: Color(0xFF6F7172), fontSize: 13),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF113F67), width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
                  ),
                ),
              ),
            ),
          ],
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
                'Submit',
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
