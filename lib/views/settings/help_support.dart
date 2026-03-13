import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupport extends StatelessWidget {
  const HelpSupport({super.key});

  // --- PHONE LAUNCHER LOGIC ---
  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri.parse('tel:+918767348954');

    try {
      if (!await launchUrl(phoneUri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open phone dialer.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Color (Navy Blue)
      backgroundColor: const Color(0xFF113F67),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/icons/arrow_icon.png',
                      height: 24,
                      width: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Help & Support',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // --- MAIN CONTENT PANEL ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Support Description Text
                      const Text(
                        'Need help with renting or listing items?\nYou can contact our support team.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF3E9ED6),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 35),

                      // Phone Number Display Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/call_icon.png',
                            height: 20,
                            width: 20,
                            color: const Color(0xFF113F67),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            '+91 8767348954',
                            style: TextStyle(
                              color: Color(0xFF113F67),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 35),

                      // --- CONTACT US BUTTON ---
                      Container(
                        width: double.infinity,
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFF91E2FB),
                          border: Border.all(
                            color: const Color(0xFF16BCE6),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: ElevatedButton(
                          onPressed: () => _launchPhone(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text(
                            'Contact Us',
                            style: TextStyle(
                              color: Color(0xFF113F67),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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
}
