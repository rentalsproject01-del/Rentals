import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/loading_widget.dart';
import 'setting_page.dart';
import 'edit_profile.dart';
import 'like_page.dart';
import '../product/product_page.dart';

import '../../services/user_service.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';

class AccPage extends StatefulWidget {
  const AccPage({super.key});

  @override
  State<AccPage> createState() => _AccPageState();
}

class _AccPageState extends State<AccPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isHostView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const SettingPage(),
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          _buildProfileHeader(context),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
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
                    child: isHostView
                        ? _buildDynamicList(true)
                        : _buildDynamicList(false),
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
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 25),
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
                      color: AppColors.white,
                      fontSize: 20,
                      fontFamily: 'Asap',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LikePage()),
                    ),
                    child: Image.asset(
                      'assets/icons/like_icon.png',
                      height: 20,
                      width: 20,
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                    child: Image.asset(
                      'assets/icons/menu_icon.png',
                      height: 18,
                      width: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<Map<String, dynamic>?>(
            stream: UserService.getUserProfileStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: LoadingWidget(),
                );
              if (snapshot.hasError)
                return const Text(
                  "Error loading profile",
                  style: TextStyle(color: Colors.redAccent),
                );
              if (!snapshot.hasData || snapshot.data == null)
                return const Text(
                  "Profile not found",
                  style: TextStyle(color: AppColors.white),
                );

              var userData = snapshot.data!;
              String name = userData['name'] ?? 'Unknown User';
              String email = userData['email'] ?? 'No email';
              String profileImg = userData['profileImageUrl'] ?? '';

              return Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
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
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfile(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
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
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontFamily: 'Asap',
                    ),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Text(
                    '70 % CIBIL Score',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              );
            },
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
              color: isHostView ? const Color(0xFF00A2FF) : AppColors.primary,
            ),
            () => setState(() => isHostView = true),
          ),
          _buildTabButton(
            "Rent",
            !isHostView,
            Image.asset(
              'assets/icons/MyRent_icon3.png',
              height: 20,
              color: !isHostView ? const Color(0xFF00A2FF) : AppColors.primary,
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
                  color: isActive ? const Color(0xFF00A2FF) : AppColors.primary,
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

  Widget _buildDynamicList(bool isHost) {
    return StreamBuilder<List<TransactionModel>>(
      stream: isHost
          ? TransactionService.getUserHosts()
          : TransactionService.getUserRents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingWidget();
        if (snapshot.hasError)
          return const Center(
            child: Text(
              "Error loading transactions.",
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return Center(
            child: Text(
              isHost ? "No items hosted yet." : "No items rented yet.",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );

        final items = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Color(0xFF9FA1A2), thickness: 1.5),
          itemBuilder: (context, index) => _buildListItem(items[index]),
        );
      },
    );
  }

  Widget _buildListItem(TransactionModel item) {
    String ratingText = item.rating != null ? item.rating.toString() : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: item.itemImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.itemImage,
                    width: 140,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.date,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$ratingText ',
                        style: const TextStyle(
                          color: AppColors.white,
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
                      'Rs. ${item.price}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (!isHostView)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductPage(
                              productData: {
                                'title': item.itemName,
                                'price': item.price,
                                'imageUrls': item.itemImage.isNotEmpty
                                    ? [item.itemImage]
                                    : [],
                                'ownerId': item.hostId,
                                'id': item.rentalId,
                              },
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          width: 55,
                          height: 27,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
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

  Widget _buildPlaceholder() => Container(
    width: 140,
    height: 90,
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.image_not_supported, color: Colors.grey),
    ),
  );
}
