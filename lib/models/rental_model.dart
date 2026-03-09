import 'package:cloud_firestore/cloud_firestore.dart';

class RentalModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final double price;
  final double deposit;
  final String category;
  final String subcategory;
  final String location;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final List<String> imageUrls;
  final String userId;
  final DateTime? createdAt;

  RentalModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.price,
    required this.deposit,
    required this.category,
    required this.subcategory,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.imageUrls,
    required this.userId,
    this.createdAt,
  });

  factory RentalModel.fromMap(Map<String, dynamic> data, String documentId) {
    return RentalModel(
      id: documentId,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      deposit: (data['deposit'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      phoneNumber: data['phoneNumber'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'price': price,
      'deposit': deposit,
      'category': category,
      'subcategory': subcategory,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'imageUrls': imageUrls,
      'userId': userId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
