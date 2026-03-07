import 'package:flutter/material.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(

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
                  margin: const EdgeInsets.only(top: 60), // Space for the floating image
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 20), // Top padding 80 to avoid overlapping image
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30),

                        // Name Field
                        _buildInputField(
                          label: 'Name :',
                          hint: 'Enter Your Name',
                          iconAsset: 'assets/icons/call_icon.png', // Replace with specific icon asset
                        ),
                        const SizedBox(height: 30),

                        // Email Field
                        _buildInputField(
                          label: 'Email address',
                          hint: 'Enter your email',
                          iconAsset: 'assets/icons/email_icon.png', 
                        ),
                        const SizedBox(height: 30),

                        // Location Field
                        _buildInputField(
                          label: 'Location',
                          hint: 'Enter your Location',
                          iconAsset: 'assets/icons/location_icon.png',
                        ),
                        const SizedBox(height: 30),

                        // Phone Field
                        _buildPhoneField(),

                        const SizedBox(height: 60),

                        // Save Button
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),

                // 2. Floating Profile Image Positioned at the seam
                Positioned(
                  top: 0, // Starts at the very top of the Stack (above white box)
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
                          child: const CircleAvatar(
                            radius: 55,
                            backgroundColor: Color(0xFFFFFFFF),
                            backgroundImage: AssetImage('assets/images/edit_profile.png'),
                          ),
                        ),
                        // The Blue Edit Icon
                        Container(
                          margin: const EdgeInsets.only(bottom: 0, right: 0),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildInputField({required String label, required String hint, required String iconAsset}) {
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF6F7172), fontSize: 13),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF113F67), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset('assets/icons/person_icon.png', height: 18, color: const Color(0xFF113F67)),
            const SizedBox(width: 8),
            const Text(
              'Phone number',
              style: TextStyle(color: Color(0xFF113F67), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Row(
          children: [
            const  Text('+91 ', style: TextStyle(color: Color(0xFF6F7172), fontSize: 14, fontWeight: FontWeight.w500)),

            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your Phone no',
                  hintStyle: const TextStyle(color: Color(0xFF6F7172), fontSize: 13),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF113F67), width: 1),
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
    return Container(
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
      child: const Center(
        child: Text(
          'Save',
          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}