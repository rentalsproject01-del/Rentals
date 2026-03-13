import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rentals/models/transaction_model.dart';

import 'myrent_card_styles.dart';

class HostRequestCard extends StatefulWidget {
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

  @override
  State<HostRequestCard> createState() => _HostRequestCardState();
}

class _HostRequestCardState extends State<HostRequestCard> {
  bool _isRejecting = false;
  bool _isAccepting = false;

  bool get _isPending => widget.transaction.status.toLowerCase() == 'pending';
  bool get _showsCountdown =>
      widget.transaction.endAt != null &&
      (widget.transaction.status.toLowerCase() == 'accepted' ||
          widget.transaction.status.toLowerCase() == 'approved');

  bool get _isBusy => _isRejecting || _isAccepting;

  Future<void> _handleReject() async {
    if (_isBusy) return;

    setState(() => _isRejecting = true);
    try {
      await widget.onReject();
    } finally {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    }
  }

  Future<void> _handleAccept() async {
    if (_isBusy) return;

    final selectedDays = await _showAcceptDialog(context);
    if (selectedDays == null) return;

    setState(() => _isAccepting = true);
    try {
      await widget.onAccept(selectedDays);
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: widget.isTarget ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: myRentTargetDecoration(widget.isTarget),
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
              child: widget.transaction.itemImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.transaction.itemImage,
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
                  widget.transaction.renterName.isNotEmpty
                      ? widget.transaction.renterName
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
                        onTap: _isBusy ? null : _handleReject,
                        child: Container(
                          width: 45,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0x26FF0000),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: _isRejecting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 14,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isBusy ? null : _handleAccept,
                        child: Container(
                          width: 45,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0x2600FF5D),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: _isAccepting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 14,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    widget.transaction.status,
                    style: TextStyle(
                      color: myRentStatusColor(widget.transaction.status),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  widget.transaction.date,
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
                  child: widget.transaction.renterImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.transaction.renterImage,
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
                      widget.remainingTimeText,
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

  Future<int?> _showAcceptDialog(BuildContext context) {
    return showDialog<int>(
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
  }
}
