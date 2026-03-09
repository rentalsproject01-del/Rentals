import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentals/views/auth/login_page.dart';

import 'package:rentals/views/profile/edit_profile.dart'; // Required import added
import 'package:rentals/views/settings/help_support.dart';
import 'package:rentals/views/settings/feedback_page.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  // --- LOGOUT LOGIC ---
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 260,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomLeft: Radius.circular(25),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        'assets/icons/arrow_back_icon.png',
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Color(0xFF113F67),
                        fontSize: 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 65),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  'GENERAL',
                  style: TextStyle(
                    color: Color(0xFF6F7172),
                    fontSize: 10,
                    fontFamily: 'Anta',
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _buildListItem(
                context,
                Image.asset('assets/icons/person_info.png', height: 14),
                'Personal Information',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfile(), // Removed const
                    ),
                  );
                },
              ),
              _buildListItem(
                context,
                Image.asset('assets/icons/notification_icon2.png', height: 14),
                'Notification',
                () {},
              ),
              _buildListItem(
                context,
                Image.asset('assets/icons/cibil_icon.png', height: 14),
                'CIBIL score',
                () {},
              ),

              const SizedBox(height: 30),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  'FeedBack',
                  style: TextStyle(
                    color: Color(0xFF6F7172),
                    fontSize: 13,
                    fontFamily: 'Anta',
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _buildListItem(
                context,
                Image.asset('assets/icons/help_icon.png', height: 14),
                'Help & Support',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupport(),
                    ),
                  );
                },
              ),
              _buildListItem(
                context,
                Image.asset('assets/icons/feedback_icon.png', height: 14),
                'Send Feedback',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: GestureDetector(
                  onTap: () => _handleLogout(context),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF91E2FB),
                      border: Border.all(
                        color: const Color(0xFF16BCE6),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/icons/logout_icon.png', height: 14),
                        const SizedBox(width: 8),
                        const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Color(0xFF113F67),
                            fontSize: 14,
                            fontFamily: 'Anta',
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Widget leadingWidget,
    String title,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 7.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF16BCE6), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
          leading: leadingWidget,
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF113F67),
              fontSize: 13,
              fontFamily: 'Anta',
            ),
          ),
          trailing: Image.asset(
            'assets/icons/arrow_forward_icon.png',
            height: 14,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
