import 'package:flutter/material.dart';
import 'dart:ui'; // Required for the blur effect
import 'package:rentals/views/product/product_page.dart';

// --- 1. DATA MODELS ---
// Note: Consider moving these to lib/models/rental_models.dart in the future
class RentItem {
  final String hostName, itemName, status, date, image;
  RentItem({
    required this.hostName,
    required this.itemName,
    required this.status,
    required this.date,
    required this.image,
  });
}

class HostItem {
  final String name, email, date, profileImg, itemImg; // Added email field
  HostItem({
    required this.name,
    required this.email,
    required this.date,
    required this.profileImg,
    required this.itemImg,
  });
}

// --- 2. MAIN PAGE ---
class MyrentPage extends StatefulWidget {
  const MyrentPage({super.key});

  @override
  State<MyrentPage> createState() => _MyrentPageState();
}

class _MyrentPageState extends State<MyrentPage> {
  bool isHostView = false;

  final Color primaryBlue = const Color(0xFF113F67);
  final Color secondaryBlue = const Color(0xFF16BCE6);
  final Color lightGrey = const Color(0xFFE9E4E4);

  final List<RentItem> rentList = [
    RentItem(
      hostName: "Aarti mahajan",
      itemName: "The Rose Gold Jewelry",
      status: "Your request has been accepted",
      date: "Thursday, 2nd Jan",
      image: "assets/images/jwellery.png",
    ),
    RentItem(
      hostName: "Palash inamdar",
      itemName: "Zara Tied Bicycle",
      status: "Your request has been accepted",
      date: "Friday, 11th Jan",
      image: "assets/images/cycle_img.png",
    ),
    RentItem(
      hostName: "John Doe",
      itemName: "CRYPTO Running shoes",
      status: "Your request has been accepted",
      date: "Sunday, 15th Jan",
      image: "assets/images/sneaker_img.png",
    ),
    RentItem(
      hostName: "Jasmin Agrwal",
      itemName: "Party wear women Dress",
      status: "Your request has been accepted",
      date: "Sunday, 15th Jan",
      image: "assets/images/dress_img.png",
    ),
  ];

  final List<HostItem> hostList = [
    HostItem(
      name: "Aarti mahajan",
      email: "aarti_mahajan@gmail.com",
      date: "Thursday, 2nd Jan",
      profileImg: "assets/images/profile_img2.png",
      itemImg: "assets/images/book_img2.png",
    ),
    HostItem(
      name: "Rushi Sing",
      email: "rushi_sing@gmail.com",
      date: "Friday, 11th Jan",
      profileImg: "assets/images/profile_img3.png",
      itemImg: "assets/images/bike_img.png",
    ),
    HostItem(
      name: "Shreya joshi",
      email: "shreya_joshi@gmail.com",
      date: "Sunday, 18th Jan",
      profileImg: "assets/images/profile_img4.png",
      itemImg: "assets/images/jacket_img.png",
    ),
    HostItem(
      name: "Pranav patil",
      email: "pranav_patil@gmail.com",
      date: "Thursday, 1 Feb",
      profileImg: "assets/images/profile_img5.png",
      itemImg: "assets/images/camera_img.png",
    ),
  ];

  // --- NEW FEATURE: PROFILE CARD DIALOG ---
  void _showProfileCard(BuildContext context, HostItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2), // Dim background slightly
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ), // Animation Blur Effect
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                color: const Color(0xFF81A9CC), // Profile card blue color
                borderRadius: BorderRadius.circular(35),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Avatar with Logo
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white24,
                        child: CircleAvatar(
                          radius: 62,
                          backgroundImage: AssetImage(item.profileImg),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0, right: 0),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Image.asset(
                            'assets/images/rentals_rlogo.png',
                            height: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.email, // Dynamic email data
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "70% CIBIL Score",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // View Account Button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16BCE6),
                      minimumSize: const Size(165, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "View Account",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon('assets/icons/map_icon2.png'),
                      const SizedBox(width: 15),
                      _buildSocialIcon('assets/icons/chat_icon2.png'),
                      const SizedBox(width: 15),
                      _buildSocialIcon('assets/icons/call_icon.png'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialIcon(String iconPath) {
    return Container(
      height: 45,
      width: 45,
      decoration: const BoxDecoration(
        color: Color(0xFF16BCE6),
        shape: BoxShape.circle,
      ),
      child: Center(child: Image.asset(iconPath, height: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 25, top: 55),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/arrow_icon.png',
                  height: 24,
                  width: 24,
                ),
                const SizedBox(width: 7),
                const Text(
                  'My Rent',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  _buildToggleSwitch(),
                  const SizedBox(height: 25),
                  Expanded(
                    child: isHostView ? _buildHostList() : _buildRentList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      width: 227,
      height: 27,
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isHostView = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHostView ? primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Host',
                  style: TextStyle(
                    color: isHostView ? Colors.white : primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isHostView = false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isHostView ? primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rent',
                  style: TextStyle(
                    color: !isHostView ? Colors.white : primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: rentList.length,
      itemBuilder: (context, index) {
        final item = rentList[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductPage(
                  productData: {
                    'title': item.itemName,
                    'price': '500', // Placeholder
                    'imageUrls': [item.image],
                  },
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    item.image,
                    width: 150,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 150,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.hostName,
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.status,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.date,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHostList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: hostList.length,
      itemBuilder: (context, index) {
        final item = hostList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 27),
          child: Row(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.grey[200],
                backgroundImage: AssetImage(item.profileImg),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: () => _showProfileCard(context, item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryBlue,
                        minimumSize: const Size(100, 25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    Text(
                      item.date,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.itemImg,
                  width: 110,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 110,
                    height: 70,
                    color: Colors.grey[300],
                    child: const Icon(Icons.shopping_bag),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
