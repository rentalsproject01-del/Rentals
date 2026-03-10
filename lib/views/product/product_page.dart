import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rentals/services/user_service.dart';
import 'package:rentals/services/transaction_service.dart';
import 'package:rentals/services/chat_service.dart';
import 'package:rentals/views/chat/chat_room_page.dart';
import 'package:rentals/views/home/home_page.dart'; // Imports AnimatedLikeButton

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
  bool _isRequesting = false;
  bool _isOpeningChat = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchOwnerData();
  }

  Future<void> _fetchOwnerData() async {
    final data = widget.productData;
    String uploaderId =
        data['ownerId']?.toString() ?? data['hostId']?.toString() ?? '';

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
      } catch (e) {
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

  Future<void> _handleCallSeller() async {
    if (_ownerPhone.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: _ownerPhone);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not open dialer on this device."),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seller phone number is unavailable.")),
      );
    }
  }

  Future<void> _handleOpenChat() async {
    if (_isOpeningChat) return;

    setState(() => _isOpeningChat = true);

    try {
      final String? currentUserId = ChatService.getCurrentUserId();
      if (currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please log in to start chatting.")),
          );
        }
        return;
      }

      final data = widget.productData;
      String ownerId =
          data['ownerId']?.toString() ?? data['hostId']?.toString() ?? '';

      if (ownerId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Seller information is missing.")),
          );
        }
        return;
      }

      if (currentUserId == ownerId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You cannot chat about your own item."),
            ),
          );
        }
        return;
      }

      // Fetch user profiles
      final rawOwnerData = await UserService.getUserById(ownerId);
      final rawRenterData = await UserService.getCurrentUserProfile();

      if (rawOwnerData == null || rawRenterData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load user profiles.")),
          );
        }
        return;
      }

      // Copy maps to ensure they are modifiable
      final ownerData = Map<String, dynamic>.from(rawOwnerData);
      final renterData = Map<String, dynamic>.from(rawRenterData);

      // Inject UIDs
      ownerData['uid'] = ownerId;
      renterData['uid'] = currentUserId;

      // Create or get the room
      final chatRoomId = await ChatService.createOrGetChatRoom(
        rentalData: data,
        ownerData: ownerData,
        renterData: renterData,
      );

      // Extract item image safely
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

      // Navigate to chat room
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  Future<void> _handleSendRequest() async {
    setState(() => _isRequesting = true);
    try {
      await TransactionService.createRentalRequest(
        rentalData: widget.productData,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request sent successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;

    // Safely extract images
    List<String> images = [];
    if (data['imageUrls'] != null) {
      if (data['imageUrls'] is List) {
        images = List<String>.from(data['imageUrls'].map((e) => e.toString()));
      } else if (data['imageUrls'] is String &&
          data['imageUrls'].toString().isNotEmpty) {
        images = [data['imageUrls'].toString()];
      }
    }

    String title = data['title']?.toString() ?? 'Unknown Item';
    String category =
        data['subcategory']?.toString() ??
        data['category']?.toString() ??
        'General';
    String price = data['price']?.toString() ?? '0';
    String duration = data['duration']?.toString() ?? '';
    String deposit = data['deposit']?.toString() ?? '0';
    String description =
        data['description']?.toString() ?? 'No description provided.';
    String rating = data['rating']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- IMAGE CAROUSEL ---
                SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      images.isNotEmpty
                          ? PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() => _currentImageIndex = index);
                              },
                              itemBuilder: (context, index) {
                                return CachedNetworkImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF16BCE6),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                      if (images.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: _currentImageIndex == index ? 22 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? const Color(0xFF113F67)
                                      : Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- TITLE & LIKE BUTTON ---
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

                      // --- CATEGORY & RATING ---
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16BCE6).withOpacity(0.15),
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

                      // --- PRICE & DEPOSIT ---
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

                      // --- OWNER SECTION ---
                      Row(
                        children: [
                          ClipOval(
                            child: _ownerImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _ownerImage,
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      width: 55,
                                      height: 55,
                                      child: const Padding(
                                        padding: EdgeInsets.all(14.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF16BCE6),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        _buildAvatarPlaceholder(),
                                  )
                                : _buildAvatarPlaceholder(),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Owner",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _isLoadingOwner
                                    ? const SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF113F67),
                                        ),
                                      )
                                    : Text(
                                        _ownerName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF113F67),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ],
                            ),
                          ),
                          // --- CALL BUTTON ---
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF16BCE6).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _handleCallSeller,
                              icon: const Icon(
                                Icons.call_outlined,
                                color: Color(0xFF16BCE6),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // --- MESSAGE BUTTON ---
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF16BCE6).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _isOpeningChat
                                  ? null
                                  : _handleOpenChat,
                              icon: _isOpeningChat
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF16BCE6),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Color(0xFF16BCE6),
                                      size: 22,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
                      const SizedBox(height: 15),

                      // --- DESCRIPTION ---
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

          // --- CUSTOM BACK BUTTON ---
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
                      color: Colors.black.withOpacity(0.15),
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

          // --- BOTTOM ACTION BAR ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF113F67), Color(0xFF217DCD)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ElevatedButton(
                        onPressed: _isRequesting ? null : _handleSendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isRequesting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Send Request",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.1,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 55,
      height: 55,
      color: Colors.grey[200],
      child: const Icon(Icons.person, color: Colors.grey, size: 30),
    );
  }
}
