import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rentals/services/user_service.dart';
import 'package:rentals/services/transaction_service.dart';
import 'package:rentals/services/chat_service.dart';
import 'package:rentals/views/chat/chat_room_page.dart';
import 'package:rentals/views/profile/owner_profile_page.dart';
import 'package:rentals/views/product/widgets/product_image_gallery.dart';
import 'package:rentals/views/product/widgets/product_owner_section.dart';
import 'package:rentals/views/product/widgets/product_request_bar.dart';
import 'package:rentals/widgets/animated_like_button.dart';
import 'package:rentals/widgets/app_feedback.dart';

class ProductPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductPage({super.key, required this.productData});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String _ownerName = "Loading...";
  String _ownerImage = "";
  String _ownerPhone = "";
  bool _isLoadingOwner = true;
  bool _isRequestInFlight = false;
  bool _isOpeningChatInFlight = false;

  String get _resolvedSellerId {
    return widget.productData['ownerId']?.toString() ??
        widget.productData['hostId']?.toString() ??
        '';
  }

  @override
  void initState() {
    super.initState();
    _fetchOwnerData();
  }

  Future<void> _fetchOwnerData() async {
    final data = widget.productData;
    final String uploaderId = _resolvedSellerId;

    if (uploaderId.isNotEmpty) {
      try {
        final userDoc = await UserService.getUserById(uploaderId);
        if (mounted) {
          setState(() {
            _ownerName =
                userDoc?['name'] ?? data['ownerName'] ?? 'Unknown Owner';
            _ownerImage =
                userDoc?['profileImageUrl'] ?? data['ownerImage'] ?? '';
            _ownerPhone = userDoc?['phone']?.toString() ?? '';
            _isLoadingOwner = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _ownerName = data['ownerName'] ?? 'Unknown Owner';
            _ownerImage = data['ownerImage'] ?? '';
            _ownerPhone = '';
            _isLoadingOwner = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _ownerName = data['ownerName'] ?? 'Unknown Owner';
          _ownerImage = data['ownerImage'] ?? '';
          _ownerPhone = '';
          _isLoadingOwner = false;
        });
      }
    }
  }

  void _openOwnerProfile() {
    final String ownerId = _resolvedSellerId;

    if (ownerId.isEmpty) {
      AppFeedback.showInfo(
        context,
        title: 'Profile Unavailable',
        message: 'Owner profile is unavailable.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerProfilePage(ownerId: ownerId),
      ),
    );
  }

  Future<void> _handleCallSeller() async {
    String phoneNumber = _ownerPhone.trim();
    if (phoneNumber.isEmpty) {
      phoneNumber = (widget.productData['phoneNumber']?.toString() ?? '')
          .trim();
    }

    if (phoneNumber.isNotEmpty) {
      final String sanitizedPhoneNumber = phoneNumber
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '');

      final Uri launchUri = Uri(scheme: 'tel', path: sanitizedPhoneNumber);

      try {
        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri);
        } else {
          if (mounted) {
            AppFeedback.showError(
              context,
              title: 'Call Unavailable',
              message: 'Could not open dialer on this device.',
            );
          }
        }
      } catch (_) {
        if (mounted) {
          AppFeedback.showError(
            context,
            title: 'Call Unavailable',
            message: 'Could not open dialer on this device.',
          );
        }
      }
    } else {
      AppFeedback.showInfo(
        context,
        title: 'Phone Unavailable',
        message: 'Seller phone number is unavailable.',
      );
    }
  }

  Future<void> _handleOpenChat() async {
    if (_isOpeningChatInFlight) return;
    _isOpeningChatInFlight = true;

    try {
      final String? currentUserId = ChatService.getCurrentUserId();
      if (currentUserId == null) {
        if (mounted) {
          AppFeedback.showInfo(
            context,
            title: 'Login Required',
            message: 'Please log in to start chatting.',
          );
        }
        return;
      }

      final data = widget.productData;
      final String ownerId = _resolvedSellerId;
      final String itemId = data['id']?.toString() ?? '';

      if (itemId.isEmpty) {
        if (mounted) {
          AppFeedback.showError(
            context,
            title: 'Item Unavailable',
            message: 'Item information is incomplete.',
          );
        }
        return;
      }

      if (ownerId.isEmpty) {
        if (mounted) {
          AppFeedback.showError(
            context,
            title: 'Seller Missing',
            message: 'Seller information is missing.',
          );
        }
        return;
      }

      if (currentUserId == ownerId) {
        if (mounted) {
          AppFeedback.showInfo(
            context,
            title: 'Unavailable Action',
            message: 'You cannot chat about your own item.',
          );
        }
        return;
      }

      final rawOwnerData = await UserService.getUserById(ownerId);
      final rawRenterData = await UserService.getCurrentUserProfile();

      if (rawOwnerData == null || rawRenterData == null) {
        if (mounted) {
          AppFeedback.showError(
            context,
            title: 'Profile Load Failed',
            message: 'Failed to load user profiles.',
          );
        }
        return;
      }

      final ownerData = Map<String, dynamic>.from(rawOwnerData);
      final renterData = Map<String, dynamic>.from(rawRenterData);

      ownerData['uid'] = ownerId;
      renterData['uid'] = currentUserId;

      final chatRoomId = await ChatService.createOrGetChatRoom(
        rentalData: data,
        ownerData: ownerData,
        renterData: renterData,
      );

      String itemImage = '';
      if (data['imageUrls'] != null) {
        if (data['imageUrls'] is List &&
            (data['imageUrls'] as List).isNotEmpty) {
          itemImage = data['imageUrls'][0].toString();
        } else if (data['imageUrls'] is String &&
            data['imageUrls'].toString().isNotEmpty) {
          itemImage = data['imageUrls'].toString();
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoomId: chatRoomId,
              currentUserId: currentUserId,
              otherUserId: ownerId,
              otherUserName: ownerData['name'] ?? 'Unknown Owner',
              otherUserImage: ownerData['profileImageUrl'] ?? '',
              itemTitle: data['title']?.toString() ?? 'Item Chat',
              itemImage: itemImage,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Chat Unavailable',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      _isOpeningChatInFlight = false;
    }
  }

  Future<void> _handleSendRequest() async {
    if (_isRequestInFlight) return;

    final String ownerId = _resolvedSellerId;
    final String itemId = widget.productData['id']?.toString() ?? '';

    if (itemId.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Item Unavailable',
        message: 'Item information is incomplete.',
      );
      return;
    }

    if (ownerId.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Seller Missing',
        message: 'Seller information is missing.',
      );
      return;
    }

    _isRequestInFlight = true;
    try {
      await TransactionService.createRentalRequest(
        rentalData: widget.productData,
      );
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: 'Request Sent',
          message: 'Your rental request was sent successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Request Failed',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      _isRequestInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;

    List<String> images = [];
    if (data['imageUrls'] != null) {
      if (data['imageUrls'] is List) {
        images = List<String>.from(data['imageUrls'].map((e) => e.toString()));
      } else if (data['imageUrls'] is String &&
          data['imageUrls'].toString().isNotEmpty) {
        images = [data['imageUrls'].toString()];
      }
    }

    final String title = data['title']?.toString() ?? 'Unknown Item';
    final String category =
        data['subcategory']?.toString() ??
        data['category']?.toString() ??
        'General';
    final String price = data['price']?.toString() ?? '0';
    final String duration = data['duration']?.toString() ?? '';
    final String deposit = data['deposit']?.toString() ?? '0';
    final String description =
        data['description']?.toString() ?? 'No description provided.';
    final String rating = data['rating']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(child: ProductImageGallery(images: images)),
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF113F67),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedLikeButton(deal: data),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF16BCE6,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                color: Color(0xFF16BCE6),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Rent Price",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Rs. $price",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF113F67),
                                    ),
                                  ),
                                  if (duration.isNotEmpty)
                                    Text(
                                      " / $duration",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: 1.5,
                            height: 45,
                            color: Colors.grey[300],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Security Deposit",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Rs. $deposit",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF113F67),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
                      const SizedBox(height: 15),
                      ProductOwnerSection(
                        ownerImage: _ownerImage,
                        ownerName: _ownerName,
                        isLoadingOwner: _isLoadingOwner,
                        onOpenOwnerProfile: _openOwnerProfile,
                        onCallSeller: _handleCallSeller,
                        onOpenChat: _handleOpenChat,
                      ),
                      const SizedBox(height: 15),
                      const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
                      const SizedBox(height: 15),
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF113F67),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 55,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF113F67),
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ProductRequestBar(onSendRequest: _handleSendRequest),
          ),
        ],
      ),
    );
  }
}
