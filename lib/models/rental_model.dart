import 'package:cloud_firestore/cloud_firestore.dart';

class RentalModel {
  final String? id;
  final String title;
  final String subtitle;
  final String description;
  final double deposit;
  final double price;
  final String duration;
  final String category;
  final String subcategory;
  final String location;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final List<String> imageUrls;
  final String ownerId;
  final String ownerName;
  final String ownerImage;
  final DateTime? createdAt;

  RentalModel({
    this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.deposit,
    required this.price,
    required this.duration,
    required this.category,
    required this.subcategory,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.imageUrls,
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    this.createdAt,
  });

  factory RentalModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return RentalModel(
      id: documentId,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      deposit: (map['deposit'] is num)
          ? (map['deposit'] as num).toDouble()
          : 0.0,
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      duration: map['duration'] ?? '',
      category: map['category'] ?? '',
      subcategory: map['subcategory'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] is num)
          ? (map['latitude'] as num).toDouble()
          : 0.0,
      longitude: (map['longitude'] is num)
          ? (map['longitude'] as num).toDouble()
          : 0.0,
      phoneNumber: map['phoneNumber'] ?? '',
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : [],
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerImage: map['ownerImage'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'deposit': deposit,
      'price': price,
      'duration': duration,
      'category': category,
      'subcategory': subcategory,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'imageUrls': imageUrls,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
