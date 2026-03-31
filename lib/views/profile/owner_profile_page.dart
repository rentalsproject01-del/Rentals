import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rentals/services/user_service.dart';
import 'package:rentals/services/rental_service.dart';
import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/widgets/app_feedback.dart';

class OwnerProfilePage extends StatefulWidget {
  final String ownerId;

  const OwnerProfilePage({super.key, required this.ownerId});

  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  late Future<Map<String, dynamic>?> _ownerProfileFuture;

  @override
  void initState() {
    super.initState();
    _ownerProfileFuture = UserService.getUserById(widget.ownerId);
  }

  void _showUnavailableMessage(String message) {
    if (!mounted) return;
    AppFeedback.showInfo(context, title: 'Unavailable', message: message);
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.trim().isEmpty) {
      _showUnavailableMessage('Phone number is unavailable.');
      return;
    }

    final String sanitizedPhone = phone
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    final Uri uri = Uri(scheme: 'tel', path: sanitizedPhone);

    try {
      if (!await launchUrl(uri)) {
        _showUnavailableMessage('Could not open dialer.');
      }
    } catch (_) {
      _showUnavailableMessage('Could not open dialer.');
    }
  }

  Future<void> _launchEmail(String email) async {
    if (email.trim().isEmpty) {
      _showUnavailableMessage('Email address is unavailable.');
      return;
    }

    final Uri uri = Uri(scheme: 'mailto', path: email);

    try {
      if (!await launchUrl(uri)) {
        _showUnavailableMessage('Could not open email app.');
      }
    } catch (_) {
      _showUnavailableMessage('Could not open email app.');
    }
  }

  Future<void> _launchLocation(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
      _showUnavailableMessage('Location is unavailable.');
      return;
    }

    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showUnavailableMessage('Could not open maps.');
      }
    } catch (_) {
      _showUnavailableMessage('Could not open maps.');
    }
  }

  Widget _buildProfileImage(String imageUrl, {double size = 100}) {
    if (imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: Icon(Icons.person, size: size * 0.45, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: Icon(Icons.person, size: size * 0.45, color: Colors.grey),
      ),
    );
  }

  Widget _buildGradientIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.55,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xFF16BCE6), Color(0xFF00A2FF)],
                ),
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 20)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF113F67),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String value,
    required String fallback,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF16BCE6), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : fallback,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: value.isNotEmpty
                  ? const Color(0xFF113F67)
                  : const Color(0xFF6F7172),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRentalImage(Map<String, dynamic> itemData) {
    String imageUrl = '';

    final dynamic imageUrls = itemData['imageUrls'];
    if (imageUrls is List && imageUrls.isNotEmpty) {
      imageUrl = imageUrls.first.toString();
    } else if (imageUrls is String && imageUrls.isNotEmpty) {
      imageUrl = imageUrls;
    }

    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerRentalsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: RentalService.getRentalsForOwner(widget.ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF113F67)),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Failed to load owner items.',
                style: TextStyle(color: Colors.redAccent, fontSize: 15),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: Text(
                'No items uploaded yet.',
                style: TextStyle(
                  color: Color(0xFF6F7172),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final items = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              items[index],
            );

            final String title = data['title']?.toString() ?? 'Unknown Item';
            final String subtitle =
                data['subtitle']?.toString() ??
                data['subcategory']?.toString() ??
                data['category']?.toString() ??
                '';
            final String price = data['price']?.toString() ?? '0';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductPage(productData: data),
                  ),
                );
              },
              child: Column(
                children: [
                  const Divider(
                    color: Color(0xFF9FA1A2),
                    thickness: 1,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 160,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9E4E4),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: _buildRentalImage(data),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF113F67),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              Text(
                                "Rs. $price",
                                style: const TextStyle(
                                  color: Color(0xFF113F67),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index == items.length - 1)
                    const Divider(
                      color: Color(0xFF9FA1A2),
                      thickness: 1,
                      height: 1,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _ownerProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF113F67),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildErrorState('Owner profile not found.');
        }

        final Map<String, dynamic> ownerData = snapshot.data!;
        final String ownerName =
            ownerData['name']?.toString().trim().isNotEmpty == true
            ? ownerData['name'].toString()
            : 'Unknown Owner';
        final String profileImageUrl =
            ownerData['profileImageUrl']?.toString() ?? '';
        final String phone = ownerData['phone']?.toString() ?? '';
        final String email = ownerData['email']?.toString() ?? '';
        final double? latitude = ownerData['latitude'] as double?;
        final double? longitude = ownerData['longitude'] as double?;
        final String locationLabel = UserService.getLocationLabel(
          location: ownerData['location']?.toString(),
          latitude: latitude,
          longitude: longitude,
        );

        return Scaffold(
          backgroundColor: const Color(0xFF113F67),
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, left: 20, bottom: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Asap',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: 50,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _buildProfileImage(
                                    profileImageUrl,
                                    size: 100,
                                  ),
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16BCE6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            ownerName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF113F67),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phone.isNotEmpty ? phone : 'Public Owner Profile',
                            style: const TextStyle(
                              color: Color(0xFF6F7172),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8BA6C1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade300,
                                  ),
                                  child: ClipOval(
                                    child: _buildProfileImage(
                                      profileImageUrl,
                                      size: 45,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ownerName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                      if (email.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        icon: Icons.phone_outlined,
                                        value: phone,
                                        fallback: 'Phone not shared',
                                      ),
                                      const SizedBox(height: 6),
                                      _buildInfoRow(
                                        icon: Icons.email_outlined,
                                        value: email,
                                        fallback: 'Email not shared',
                                      ),
                                      const SizedBox(height: 6),
                                      _buildInfoRow(
                                        icon: Icons.location_on_outlined,
                                        value: locationLabel,
                                        fallback: 'Location not shared',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 35),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildGradientIconButton(
                                  icon: Icons.phone_rounded,
                                  label: 'Call',
                                  isEnabled: phone.isNotEmpty,
                                  onTap: () => _launchPhone(phone),
                                ),
                                _buildGradientIconButton(
                                  icon: Icons.email_rounded,
                                  label: 'Email',
                                  isEnabled: email.isNotEmpty,
                                  onTap: () => _launchEmail(email),
                                ),
                                _buildGradientIconButton(
                                  icon: Icons.location_on_rounded,
                                  label: 'Location',
                                  isEnabled:
                                      latitude != null && longitude != null,
                                  onTap: () =>
                                      _launchLocation(latitude, longitude),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Uploaded Items',
                                style: TextStyle(
                                  color: Color(0xFF113F67),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildOwnerRentalsList(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
