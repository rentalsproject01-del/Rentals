import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String renterId;
  final String hostId;
  final String rentalId;
  final String itemName;
  final String itemImage;
  final String price;
  final String date;
  final String status;
  final double? rating;

  // New Lifecycle Fields
  final int? rentalDays;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? startAt;
  final DateTime? endAt;

  // UI Specific Fields
  final String renterName;
  final String renterEmail;
  final String renterImage;
  final String hostName;

  TransactionModel({
    required this.id,
    required this.renterId,
    required this.hostId,
    required this.rentalId,
    required this.itemName,
    required this.itemImage,
    required this.price,
    required this.date,
    required this.status,
    this.rating,
    this.rentalDays,
    this.acceptedAt,
    this.rejectedAt,
    this.startAt,
    this.endAt,
    required this.renterName,
    required this.renterEmail,
    required this.renterImage,
    required this.hostName,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data, String id) {
    return TransactionModel(
      id: id,
      renterId: data['renterId'] ?? '',
      hostId: data['hostId'] ?? '',
      rentalId: data['rentalId'] ?? '',
      itemName: data['itemName'] ?? 'Unknown Item',
      itemImage: data['itemImage'] ?? '',
      price: data['price']?.toString() ?? '0',
      date: data['date'] ?? 'N/A',
      status: data['status'] ?? 'Pending',
      rating: data['rating'] != null
          ? double.tryParse(data['rating'].toString())
          : null,
      rentalDays: data['rentalDays'] != null
          ? int.tryParse(data['rentalDays'].toString())
          : null,
      acceptedAt: data['acceptedAt'] is Timestamp
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: data['rejectedAt'] is Timestamp
          ? (data['rejectedAt'] as Timestamp).toDate()
          : null,
      startAt: data['startAt'] is Timestamp
          ? (data['startAt'] as Timestamp).toDate()
          : null,
      endAt: data['endAt'] is Timestamp
          ? (data['endAt'] as Timestamp).toDate()
          : null,
      renterName: data['renterName'] ?? 'Unknown User',
      renterEmail: data['renterEmail'] ?? 'No email provided',
      renterImage: data['renterImage'] ?? '',
      hostName: data['hostName'] ?? 'Unknown Host',
    );
  }
}
