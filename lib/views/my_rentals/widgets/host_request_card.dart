import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rentals/models/transaction_model.dart';

import 'myrent_card_styles.dart';

class HostRequestCard extends StatelessWidget {
  const HostRequestCard({
    super.key,
    required this.transaction,
    required this.isTarget,
    required this.remainingTimeText,
    required this.onReject,
    required this.onAccept,
  });

  final TransactionModel transaction;
  final bool isTarget;
  final String remainingTimeText;
  final Future<void> Function() onReject;
  final Future<void> Function(int rentalDays) onAccept;

  bool get _isPending => transaction.status.toLowerCase() == 'pending';
  bool get _showsCountdown =>
      transaction.endAt != null &&
      (transaction.status.toLowerCase() == 'accepted' ||
          transaction.status.toLowerCase() == 'approved');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: isTarget ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: myRentTargetDecoration(isTarget),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE9E4E4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: transaction.itemImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: transaction.itemImage,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.renterName.isNotEmpty
                      ? transaction.renterName
                      : 'Unknown Renter',
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
                if (_isPending)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onReject,
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
                      GestureDetector(
                        onTap: () => _showAcceptDialog(context),
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
                    transaction.status,
                    style: TextStyle(
                      color: myRentStatusColor(transaction.status),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  transaction.date,
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
                  child: transaction.renterImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: transaction.renterImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, color: Colors.grey),
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              if (_showsCountdown) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      remainingTimeText,
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

  Future<void> _showAcceptDialog(BuildContext context) async {
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
                title: Text('$days Day${days > 1 ? 's' : ''}'),
                onTap: () => Navigator.pop(context, days),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedDays != null) {
      await onAccept(selectedDays);
    }
  }
}
