import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/loading_widget.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import '../product/product_page.dart';

class MyrentPage extends StatefulWidget {
  const MyrentPage({super.key});

  @override
  State<MyrentPage> createState() => _MyrentPageState();
}

class _MyrentPageState extends State<MyrentPage> {
  bool isHostView = false;
  final Color lightGrey = const Color(0xFFE9E4E4);

  // --- PROFILE CARD DIALOG ---
  void _showProfileCard(BuildContext context, TransactionModel transaction) {
    String profileImg = transaction.renterImage;
    String name = transaction.renterName;
    String email = transaction.renterEmail;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                color: const Color(0xFF81A9CC),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white24,
                        child: CircleAvatar(
                          radius: 62,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: profileImg.isNotEmpty
                              ? NetworkImage(profileImg)
                              : null,
                          child: profileImg.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
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
                    name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
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
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      minimumSize: const Size(165, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "View Account",
                      style: TextStyle(color: AppColors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
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
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: Center(child: Image.asset(iconPath, height: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
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
                  style: TextStyle(color: AppColors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
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
                  color: isHostView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Host',
                  style: TextStyle(
                    color: isHostView ? AppColors.white : AppColors.primary,
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
                  color: !isHostView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rent',
                  style: TextStyle(
                    color: !isHostView ? AppColors.white : AppColors.primary,
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
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService.getUserRents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingWidget();
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "You are not renting any items currently.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final transactions = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductPage(
                      productData: {
                        'title': transaction.itemName,
                        'price': transaction.price,
                        'imageUrls': transaction.itemImage.isNotEmpty
                            ? [transaction.itemImage]
                            : [],
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
                      child: transaction.itemImage.isNotEmpty
                          ? Image.network(
                              transaction.itemImage,
                              width: 150,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(150, 100),
                            )
                          : _buildPlaceholderImage(150, 100),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.hostName,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            transaction.itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            transaction.status,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            transaction.date,
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
      },
    );
  }

  Widget _buildHostList() {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService.getUserHosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingWidget();
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No requests to host your items yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final transactions = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 27),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: transaction.renterImage.isNotEmpty
                        ? NetworkImage(transaction.renterImage)
                        : null,
                    child: transaction.renterImage.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.renterName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: () =>
                              _showProfileCard(context, transaction),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            minimumSize: const Size(100, 25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'View Profile',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          transaction.date,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: transaction.itemImage.isNotEmpty
                        ? Image.network(
                            transaction.itemImage,
                            width: 110,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(110, 70),
                          )
                        : _buildPlaceholderImage(110, 70),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholderImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
