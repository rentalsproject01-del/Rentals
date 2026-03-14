import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:rentals/services/chat_service.dart';
import 'package:rentals/services/transaction_service.dart';
import 'package:rentals/services/user_service.dart';

class RentalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a new rental item, including its images to Firebase Storage,
  /// and saves the document to Firestore.
  static Future<void> uploadRental({
    required String title,
    required String subtitle,
    required String description,
    required double deposit,
    required double price,
    required String duration,
    required String category,
    required String subcategory,
    required String location,
    required double latitude,
    required double longitude,
    required String phoneNumber,
    required String email, // <-- 1. ADDED EMAIL PARAMETER HERE
    required List<File> images,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated.');
    }

    await UserService.ensureCurrentUserCanPerformWrite();

    final String uid = currentUser.uid;

    // Fetch user profile to attach owner info to the rental document
    final DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('User profile not found. Please complete profile setup.');
    }

    final Map<String, dynamic> userData =
        userDoc.data() as Map<String, dynamic>;
    final String ownerName = userData['name'] ?? 'Unknown User';
    final String ownerImage = userData['profileImageUrl'] ?? '';

    List<String> uploadedImageUrls = [];

    // Upload images to Firebase Storage
    if (images.isNotEmpty) {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      for (int i = 0; i < images.length; i++) {
        final File imageFile = images[i];
        final String filePath = 'rentals/$uid/${timestamp}_$i.jpg';
        final Reference ref = _storage.ref().child(filePath);

        final TaskSnapshot uploadTask = await ref.putFile(imageFile);
        final String downloadUrl = await uploadTask.ref.getDownloadURL();
        uploadedImageUrls.add(downloadUrl);
      }
    }

    // Save rental document to Firestore aligning with RentalModel schema
    await _firestore.collection('rentals').add({
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
      'email': email, // <-- 2. SAVED EMAIL TO FIRESTORE HERE
      'ownerId': uid,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
      'imageUrls': uploadedImageUrls,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Retrieves a stream of all rentals for the general home feed.
  static Stream<QuerySnapshot> getAllRentals() {
    return _firestore
        .collection('rentals')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Retrieves a stream of all rentals and fetches owner names from the users collection
  /// if they are missing from the rental document.
  static Stream<List<Map<String, dynamic>>> getAllRentalsWithOwnerNames() {
    return _firestore
        .collection('rentals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((QuerySnapshot snapshot) async {
          List<Map<String, dynamic>> enrichedRentals = [];

          for (var doc in snapshot.docs) {
            // Create a modifiable map from the document data
            final data = Map<String, dynamic>.from(
              doc.data() as Map<String, dynamic>,
            );
            data['id'] = doc.id; // Keep doc id for reference

            String ownerName = data['ownerName']?.toString() ?? '';

            // If ownerName is missing, try to resolve it using ownerId or hostId
            if (ownerName.trim().isEmpty) {
              String uploaderId =
                  data['ownerId']?.toString() ??
                  data['hostId']?.toString() ??
                  '';

              if (uploaderId.isNotEmpty) {
                try {
                  final userDoc = await _firestore
                      .collection('users')
                      .doc(uploaderId)
                      .get();
                  if (userDoc.exists && userDoc.data() != null) {
                    final userData = userDoc.data() as Map<String, dynamic>;
                    data['ownerName'] = userData['name'] ?? 'Unknown Owner';
                  } else {
                    data['ownerName'] = 'Unknown Owner';
                  }
                } catch (e) {
                  data['ownerName'] = 'Unknown Owner';
                }
              } else {
                data['ownerName'] = 'Unknown Owner';
              }
            }

            enrichedRentals.add(data);
          }

          return enrichedRentals;
        });
  }

  /// Retrieves all rentals once and ensures owner names are populated for search.
  static Future<List<Map<String, dynamic>>>
  fetchAllRentalsWithOwnerNames() async {
    final QuerySnapshot snapshot = await _firestore
        .collection('rentals')
        .orderBy('createdAt', descending: true)
        .get();

    List<Map<String, dynamic>> enrichedRentals = [];

    for (var doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );
      data['id'] = doc.id;
      data['ownerName'] = await _resolveOwnerName(data);
      enrichedRentals.add(data);
    }

    return enrichedRentals;
  }

  /// Filters rentals against user-entered search text using case-insensitive matching.
  static List<Map<String, dynamic>> filterRentalsByQuery(
    List<Map<String, dynamic>> rentals,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    return rentals.where((rental) {
      return _searchableFields(
        rental,
      ).any((field) => field.contains(normalizedQuery));
    }).toList();
  }

  static Future<String> _resolveOwnerName(Map<String, dynamic> data) async {
    final existingOwnerName = data['ownerName']?.toString().trim() ?? '';
    if (existingOwnerName.isNotEmpty) {
      return existingOwnerName;
    }

    final uploaderId =
        data['ownerId']?.toString() ?? data['hostId']?.toString() ?? '';

    if (uploaderId.isEmpty) {
      return 'Unknown Owner';
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(uploaderId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['name']?.toString().trim().isNotEmpty == true
            ? userData['name'].toString().trim()
            : 'Unknown Owner';
      }
    } catch (e) {
      // Fall through to the default owner name.
    }

    return 'Unknown Owner';
  }

  static List<String> _searchableFields(Map<String, dynamic> rental) {
    return [
      rental['title'],
      rental['category'],
      rental['subcategory'],
      rental['ownerName'],
    ].map((value) => value?.toString().trim().toLowerCase() ?? '').toList();
  }

  /// Retrieves a stream of rentals created by a specific user.
  static Stream<QuerySnapshot> getUserRentals(String uid) {
    return _firestore
        .collection('rentals')
        .where('ownerId', isEqualTo: uid)
        .snapshots();
  }

  /// Retrieves rentals created by a specific owner, supporting both ownerId and legacy hostId fields.
  static Stream<List<Map<String, dynamic>>> getRentalsForOwner(String uid) {
    return _firestore
        .collection('rentals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => {
                  ...Map<String, dynamic>.from(doc.data()),
                  'id': doc.id,
                },
              )
              .where((data) {
                final ownerId = data['ownerId']?.toString() ?? '';
                final hostId = data['hostId']?.toString() ?? '';
                return ownerId == uid || hostId == uid;
              })
              .toList();
        });
  }

  static Future<void> deleteRentalIfAllowed(String rentalId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated.');
    }

    await UserService.ensureCurrentUserCanPerformWrite();

    final rentalRef = _firestore.collection('rentals').doc(rentalId);
    final rentalSnap = await rentalRef.get();

    if (!rentalSnap.exists || rentalSnap.data() == null) {
      throw Exception('This item no longer exists.');
    }

    final rentalData = Map<String, dynamic>.from(rentalSnap.data()!);
    final ownerId =
        rentalData['ownerId']?.toString() ??
        rentalData['hostId']?.toString() ??
        '';

    if (ownerId.isEmpty || ownerId != currentUser.uid) {
      throw Exception('Only the item owner can delete this listing.');
    }

    final hasBlockingTransactions =
        await TransactionService.hasBlockingTransactionsForRental(rentalId);
    if (hasBlockingTransactions) {
      throw Exception(
        'This item cannot be deleted because it has active or pending rental requests.',
      );
    }

    final transactionDocs = await TransactionService.getTransactionsForRental(
      rentalId,
    );
    final batch = _firestore.batch();

    for (final transactionDoc in transactionDocs) {
      batch.delete(transactionDoc.reference);
    }

    batch.delete(rentalRef);
    await ChatService.deleteChatRoomsAndMessagesForItem(rentalId, batch: batch);

    await batch.commit();
    await _deleteRentalImages(rentalData['imageUrls']);
  }

  static Future<void> _deleteRentalImages(dynamic imageUrls) async {
    final List<String> urls = [];

    if (imageUrls is List) {
      for (final image in imageUrls) {
        final url = image?.toString().trim() ?? '';
        if (url.isNotEmpty) {
          urls.add(url);
        }
      }
    } else if (imageUrls is String && imageUrls.trim().isNotEmpty) {
      urls.add(imageUrls.trim());
    }

    for (final url in urls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (e) {
        final message = e.toString().toLowerCase();
        if (!message.contains('object-not-found') &&
            !message.contains('no object exists')) {
          debugPrint('Failed to delete rental image $url: $e');
        }
      }
    }
  }

  /// Retrieves a stream of all rentals for client-side geospatial filtering.
  static Stream<QuerySnapshot> getNearbyCandidates() {
    return _firestore.collection('rentals').snapshots();
  }
}
