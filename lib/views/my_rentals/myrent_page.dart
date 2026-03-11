import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:rentals/services/rental_service.dart';
import 'package:rentals/services/transaction_service.dart';
import 'package:rentals/models/transaction_model.dart';
import 'package:rentals/views/product/product_page.dart';

class MyrentPage extends StatefulWidget {
  const MyrentPage({super.key});

  @override
  State<MyrentPage> createState() => _MyrentPageState();
}

class _MyrentPageState extends State<MyrentPage> {
  // true = Host tab, false = Rent tab
  bool isHostMode = true;
  // true = Listings sub-tab, false = Requests sub-tab (only applies when isHostMode is true)
  bool isHostListingsMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: Column(
        children: [
          // --- HEADER & TOGGLE ---
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 25, top: 60),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'My Rentals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // --- MAIN CONTENT ---
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
                  const SizedBox(height: 25),
                  _buildToggleSwitch(),

                  // Secondary Toggle for Host Mode
                  if (isHostMode) ...[
                    const SizedBox(height: 15),
                    _buildHostSubToggleSwitch(),
                    const SizedBox(height: 20),
                  ] else ...[
                    const SizedBox(height: 35),
                  ],

                  Expanded(
                    child: isHostMode
                        ? (isHostListingsMode
                              ? _buildUploadedItemsList()
                              : _buildHostRequestsList())
                        : _buildRentedItemsList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Main Host / Rent Toggle
  Widget _buildToggleSwitch() {
    return Container(
      width: 200,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E4E4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isHostMode = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHostMode
                      ? const Color(0xFF113F67)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Host',
                  style: TextStyle(
                    color: isHostMode ? Colors.white : const Color(0xFF113F67),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isHostMode = false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isHostMode
                      ? const Color(0xFF113F67)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rent',
                  style: TextStyle(
                    color: !isHostMode ? Colors.white : const Color(0xFF113F67),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sub-toggle for Host: Listings / Requests
  Widget _buildHostSubToggleSwitch() {
    return Container(
      width: 180,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isHostListingsMode = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHostListingsMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isHostListingsMode
                      ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                      : [],
                ),
                child: const Text(
                  'Listings',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF113F67),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isHostListingsMode = false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isHostListingsMode
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !isHostListingsMode
                      ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                      : [],
                ),
                child: const Text(
                  'Requests',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF113F67),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Time Calculation
  String _getRemainingTimeText(DateTime? endAt) {
    if (endAt == null) return '--d : --h : --m';
    final now = DateTime.now();
    if (endAt.isBefore(now)) return 'Ended';
    final diff = endAt.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    return '${days.toString().padLeft(2, '0')}d : ${hours.toString().padLeft(2, '0')}h : ${mins.toString().padLeft(2, '0')}m';
  }

  // ---------------------------------------------------------------------------
  // HOST TAB -> LISTINGS
  // ---------------------------------------------------------------------------
  Widget _buildUploadedItemsList() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("User not logged in."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: RentalService.getUserRentals(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF113F67)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "You have not uploaded any items yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = Map<String, dynamic>.from(
              docs[index].data() as Map<String, dynamic>,
            );
            data['id'] = docs[index].id;
            return _buildUploadedItemCard(data);
          },
        );
      },
    );
  }

  Widget _buildUploadedItemCard(Map<String, dynamic> data) {
    String imageUrl = '';
    if (data['imageUrls'] != null) {
      if (data['imageUrls'] is List && (data['imageUrls'] as List).isNotEmpty) {
        imageUrl = data['imageUrls'][0].toString();
      } else if (data['imageUrls'] is String &&
          data['imageUrls'].toString().isNotEmpty) {
        imageUrl = data['imageUrls'].toString();
      }
    }

    String title = data['title']?.toString() ?? 'Unknown Title';
    String price = data['price']?.toString() ?? '0';
    String category =
        data['subcategory']?.toString() ?? data['category']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(productData: data),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Item Image
            Container(
              width: 120,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E4E4),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 15),

            // Middle: Title & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF113F67),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6F7172),
                      fontSize: 12,
                      fontFamily: 'Inria Serif',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Rs. $price",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16BCE6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HOST TAB -> REQUESTS
  // ---------------------------------------------------------------------------
  Widget _buildHostRequestsList() {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService.getUserHosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF113F67)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No one has requested your items yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final transactions = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildHostRequestCard(transactions[index]);
          },
        );
      },
    );
  }

  Widget _buildHostRequestCard(TransactionModel tx) {
    Color statusColor = Colors.grey;
    if (tx.status.toLowerCase() == 'pending') statusColor = Colors.orange;
    if (tx.status.toLowerCase() == 'approved' ||
        tx.status.toLowerCase() == 'accepted') {
      statusColor = Colors.green;
    }
    if (tx.status.toLowerCase() == 'rejected') statusColor = Colors.red;

    bool isPending = tx.status.toLowerCase() == 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Item Image
          Container(
            width: 100,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE9E4E4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: tx.itemImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: tx.itemImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 15),

          // Middle: Renter Name, Actions/Status, Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.renterName.isNotEmpty ? tx.renterName : 'Unknown Renter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF113F67),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if (isPending)
                  Row(
                    children: [
                      // Reject Button
                      GestureDetector(
                        onTap: () async {
                          try {
                            await TransactionService.rejectRentalRequest(
                              transactionId: tx.id,
                            );
                          } catch (e) {
                            debugPrint('Failed to reject: $e');
                          }
                        },
                        child: Container(
                          width: 45,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0x26FF0000),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Accept Button
                      GestureDetector(
                        onTap: () async {
                          final selectedDays = await showDialog<int>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text(
                                  'Select Rental Days',
                                  style: TextStyle(
                                    color: Color(0xFF113F67),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [1, 2, 3, 4, 5, 6, 7].map((days) {
                                    return ListTile(
                                      title: Text(
                                        '$days Day${days > 1 ? 's' : ''}',
                                      ),
                                      onTap: () => Navigator.pop(context, days),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );

                          if (selectedDays != null) {
                            try {
                              await TransactionService.acceptRentalRequest(
                                transactionId: tx.id,
                                rentalDays: selectedDays,
                              );
                            } catch (e) {
                              debugPrint('Failed to accept: $e');
                            }
                          }
                        },
                        child: Container(
                          width: 45,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0x2600FF5D),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.green,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    tx.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  tx.date,
                  style: const TextStyle(
                    color: Color(0xFF6F7172),
                    fontSize: 12,
                    fontFamily: 'Inria Serif',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          // Right: Renter Profile Image & Timer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: ClipOval(
                  child: tx.renterImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: tx.renterImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, color: Colors.grey),
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              if (tx.endAt != null &&
                  (tx.status.toLowerCase() == 'accepted' ||
                      tx.status.toLowerCase() == 'approved')) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getRemainingTimeText(tx.endAt),
                      style: const TextStyle(
                        color: Color(0xFF6F7172),
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.access_time,
                      size: 10,
                      color: Color(0xFF6F7172),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RENT TAB: Items rented / requested by the current user
  // ---------------------------------------------------------------------------
  Widget _buildRentedItemsList() {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService.getUserRents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF113F67)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "You have not requested or rented any items yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final transactions = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(transactions[index]);
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    Color statusColor = Colors.grey;
    if (tx.status.toLowerCase() == 'pending') statusColor = Colors.orange;
    if (tx.status.toLowerCase() == 'approved' ||
        tx.status.toLowerCase() == 'accepted') {
      statusColor = Colors.green;
    }
    if (tx.status.toLowerCase() == 'rejected') statusColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Item Image
          Container(
            width: 120,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE9E4E4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: tx.itemImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: tx.itemImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 15),

          // Middle: Title & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Requested: ${tx.date}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6F7172),
                    fontSize: 12,
                    fontFamily: 'Inria Serif',
                    fontWeight: FontWeight.w300,
                  ),
                ),
                if (tx.endAt != null &&
                    (tx.status.toLowerCase() == 'accepted' ||
                        tx.status.toLowerCase() == 'approved')) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Color(0xFF16BCE6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getRemainingTimeText(tx.endAt),
                        style: const TextStyle(
                          color: Color(0xFF16BCE6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Right: Status & Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Rs. ${tx.price}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16BCE6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
