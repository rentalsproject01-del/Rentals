import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  // --- EMAIL LAUNCHER LOGIC ---
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri.parse(
      'mailto:rentalsproject01@gmail.com?subject=Rentals App Feedback',
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email client.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No email client found. Please check your device settings.',
            ),
          ),
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
                      'assets/icons/arrow_icon.png', // Back arrow icon
                      height: 24,
                      width: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Feedback',
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

                      // Feedback Description Text
                      const Text(
                        'We value your feedback. If you have any\nsuggestions, questions, or issues while\nusing the Rentals app, please feel free to\ncontact us. Your feedback helps us\nimprove our services.',
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

                      // Email Display Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/email_icon.png',
                            height: 20,
                            width: 20,
                            color: const Color(0xFF113F67),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'rentalsproject01@gmail.com',
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

                      // --- SEND EMAIL BUTTON ---
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
                          onPressed: () => _launchEmail(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text(
                            'Send Email',
                            style: TextStyle(
                              color: Color(
                                0xFF113F67,
                              ), // High contrast text color
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
