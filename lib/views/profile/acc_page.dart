// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

// --- FIXED IMPORTS FOR NEW FOLDER STRUCTURE ---
import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/views/profile/like_page.dart';
import 'package:rentals/views/profile/edit_profile.dart'; // Added Edit Profile import

class AccPage extends StatefulWidget {
  const AccPage({super.key});

  @override
  State<AccPage> createState() => _AccPageState();
}

class _AccPageState extends State<AccPage> {
  bool isHostView = true;

  final List<Map<String, String>> hostList = [
    {
      'title': 'The Design of Everyday Things',
      'subtitle': 'author Don Norman',
      'rating': '3.7',
      'price': 'Rs.',
      'image': 'assets/images/book_img.png',
    },
    {
      'title': 'Zara Tied Satin Effect Front Blazer',
      'subtitle': 'Hot Pink Jacket & Coat',
      'rating': '4.7',
      'price': 'Rs.',
      'image': 'assets/images/jacket_img.png',
    },
    {
      'title': 'Sony Camera',
      'subtitle': 'a7 | Mirrorless',
      'rating': '3.3',
      'price': 'Rs.',
      'image': 'assets/images/camera_img.png',
    },
  ];

  final List<Map<String, String>> rentList = [
    {
      'title': 'The Rose Gold Jewellery',
      'subtitle': 'Bracelet | Neckless | Earrings | Rings',
      'rating': '3.7',
      'price': 'Rs.',
      'image': 'assets/images/jwellery.png',
    },
    {
      'title': 'Zara Tied Satin Effect Front Blazer',
      'subtitle': 'Hot Pink Jacket & Coat',
      'rating': '4.7',
      'price': 'Rs.',
      'image': 'assets/images/cycle_img.png',
    },
    {
      'title': 'white Sneakers',
      'subtitle': 'Sneaker',
      'rating': '3.3',
      'price': 'Rs.',
      'image': 'assets/images/sneaker_img.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: Column(
        children: [
          _buildProfileHeader(context),
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
              child: Column(
                children: [
                  _buildToggleTab(),
                  const Divider(height: 1, color: Color(0xFF6F7172)),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      itemCount: isHostView ? hostList.length : rentList.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: Color(0xFF9FA1A2),
                        thickness: 1.5,
                      ),
                      itemBuilder: (context, index) {
                        final item = isHostView
                            ? hostList[index]
                            : rentList[index];
                        return _buildListItem(item);
                      },
                    ),
                  ),
                  const SizedBox(height: 85),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/icons/arrow_icon.png', height: 24),
                  const SizedBox(width: 7),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Asap',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LikePage(),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/icons/like_icon.png',
                      height: 20,
                      width: 20,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Image.asset(
                    'assets/icons/menu_icon.png',
                    height: 18,
                    width: 18,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/profile_img.png'),
              ),
              // --- ADDED GESTURE DETECTOR FOR EDIT PROFILE ---
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfile(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16BCE6),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/icons/edit_icon.png',
                      height: 12,
                      width: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Nancy Max Wheeler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Asap',
            ),
          ),
          const Text(
            'nancy_wheeler@gmail.com',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Text(
            '70 % CIBIL Score',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabButton(
            "Host",
            isHostView,
            Image.asset(
              'assets/icons/host_icon.png',
              height: 20,
              color: isHostView
                  ? const Color(0xFF00A2FF)
                  : const Color(0xFF113F67),
            ),
            () => setState(() => isHostView = true),
          ),
          _buildTabButton(
            "Rent",
            !isHostView,
            Image.asset(
              'assets/icons/MyRent_icon3.png',
              height: 20,
              color: !isHostView
                  ? const Color(0xFF00A2FF)
                  : const Color(0xFF113F67),
            ),
            () => setState(() => isHostView = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    bool isActive,
    Widget icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isActive
                      ? const Color(0xFF00A2FF)
                      : const Color(0xFF113F67),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (isActive)
            Container(width: 80, height: 1.5, color: const Color(0xFF00A2FF)),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, String> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              item['image']!,
              width: 140,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  item['subtitle']!,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF113F67),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item['rating']} ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      Image.asset(
                        'assets/icons/star_icon.png',
                        height: 12,
                        width: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['price']!,
                      style: const TextStyle(
                        color: Color(0xFF113F67),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (!isHostView)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          width: 55,
                          height: 27,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF113F67)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset("assets/icons/rent_icon.png"),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
