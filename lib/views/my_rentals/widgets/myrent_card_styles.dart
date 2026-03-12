import 'package:flutter/material.dart';

Color myRentStatusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized == 'pending') return Colors.orange;
  if (normalized == 'approved' || normalized == 'accepted') {
    return Colors.green;
  }
  if (normalized == 'rejected') return Colors.red;
  return Colors.grey;
}

BoxDecoration? myRentTargetDecoration(bool isTarget) {
  if (!isTarget) return null;
  return BoxDecoration(
    color: const Color(0xFF16BCE6).withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(15),
    border: Border.all(
      color: const Color(0xFF16BCE6).withValues(alpha: 0.5),
      width: 1.5,
    ),
  );
}
