import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rentals/models/transaction_model.dart';

import 'myrent_card_styles.dart';

class RentTransactionCard extends StatelessWidget {
  const RentTransactionCard({
    super.key,
    required this.transaction,
    required this.isTarget,
    required this.remainingTimeText,
  });

  final TransactionModel transaction;
  final bool isTarget;
  final String remainingTimeText;

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
            width: 120,
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
                  transaction.itemName,
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
                  'Requested: ${transaction.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6F7172),
                    fontSize: 12,
                    fontFamily: 'Inria Serif',
                    fontWeight: FontWeight.w300,
                  ),
                ),
                if (_showsCountdown) ...[
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
                        remainingTimeText,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.status,
                style: TextStyle(
                  color: myRentStatusColor(transaction.status),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Rs. ${transaction.price}',
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
