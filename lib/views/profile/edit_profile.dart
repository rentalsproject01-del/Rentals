import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentals/services/user_service.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  // --- CONTROLLERS ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // --- STATE VARIABLES ---
  File? _imageFile;
  String? _networkImageUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- LOAD EXISTING USER DATA ---
  void _loadUserData() async {
    try {
      // Listen to the stream once to populate initial values
      final userData = await UserService.getUserProfileStream().first;

      if (userData != null && mounted) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          // Firestore stores lat/lng, so we show a placeholder or mapped value
          _locationController.text = (userData['latitude'] != null)
              ? 'Location Set'
              : '';
          _networkImageUrl = userData['profileImageUrl'];
        });
      }
    } catch (e) {
      debugPrint("Failed to load user data: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- PICK IMAGE ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Added image compression
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
    }
  }

  // --- SAVE/UPDATE PROFILE ---
  Future<void> _updateProfile() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Phone cannot be empty.")),
      );
      return;
    }

    // Added phone number regex validation
    if (!RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number must be exactly 10 digits")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? uploadedImageUrl;

      // 1. Upload new image if selected
      if (_imageFile != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          // Improved Firebase Storage upload path to prevent cache issues
          Reference ref = FirebaseStorage.instance.ref().child(
            'profile_images/$uid/profile.jpg',
          );

          await ref.putFile(_imageFile!);
          uploadedImageUrl = await ref.getDownloadURL();
        }
      }

      // 2. Update Firestore using existing UserService
      await UserService.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profileImageUrl:
            uploadedImageUrl, // Only updates if a new one was uploaded
      );

      // 3. Success Behavior
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper method for safe ImageProvider assignment
  ImageProvider _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_networkImageUrl != null && _networkImageUrl!.isNotEmpty) {
      return NetworkImage(_networkImageUrl!);
    } else {
      return const AssetImage('assets/images/edit_profile.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // Background Color: #113F67 (Dark Blue)
        backgroundColor: const Color(0xFF113F67),
        body: Column(
          children: [
            // --- HEADER SECTION ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/icons/arrow_icon.png', // Using your asset path
                      height: 24,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // --- OVERLAPPING BODY SECTION ---
            Expanded(
              child: Stack(
                clipBehavior: Clip.none, // Allows the profile image to pop out
                children: [
                  // 1. White Container (The Form Area)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    margin: const EdgeInsets.only(
                      top: 60,
                    ), // Space for the floating image
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        80,
                        20,
                        20,
                      ), // Top padding 80 to avoid overlapping image
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),

                          // Name Field
                          _buildInputField(
                            label: 'Name :',
                            hint: 'Enter Your Name',
                            iconAsset: 'assets/icons/call_icon.png',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 30),

                          // Email Field (Read Only)
                          _buildInputField(
                            label: 'Email address',
                            hint: 'Enter your email',
                            iconAsset: 'assets/icons/email_icon.png',
                            controller: _emailController,
                            enabled: false,
                          ),
                          const SizedBox(height: 30),

                          // Location Field (Read Only, typically updated via Map)
                          _buildInputField(
                            label: 'Location',
                            hint: 'Enter your Location',
                            iconAsset: 'assets/icons/location_icon.png',
                            controller: _locationController,
                            enabled: false,
                          ),
                          const SizedBox(height: 30),

                          // Phone Field
                          _buildPhoneField(controller: _phoneController),

                          const SizedBox(height: 60),

                          // Save Button
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),

                  // 2. Floating Profile Image Positioned at the seam
                  Positioned(
                    top:
                        0, // Starts at the very top of the Stack (above white box)
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // The Circular Border and Image
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF16BCE6),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: const Color(0xFFFFFFFF),
                              backgroundImage:
                                  _getProfileImage(), // Safe ImageProvider logic
                            ),
                          ),
                          // The Blue Edit Icon
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: 0,
                                right: 0,
                              ),
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Color(0xFF16BCE6),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/icons/edit_icon.png',
                                height: 18,
                                width: 18,
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
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildInputField({
    required String label,
    required String hint,
    required String iconAsset,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(iconAsset, height: 18, color: const Color(0xFF113F67)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF113F67),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          // Ensuring disabled text color is grey
          style: TextStyle(
            color: enabled ? const Color(0xFF113F67) : Colors.grey,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF6F7172), fontSize: 13),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF113F67), width: 1),
            ),
            disabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: const TextStyle(color: Color(0xFF113F67)),
                decoration: const InputDecoration(
                  hintText: 'Enter your Phone no',
                  counterText: "", // Hides the counter
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

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _updateProfile,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF16BCE6), Color(0xFF00A2FF)],
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
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
                  'Save',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
