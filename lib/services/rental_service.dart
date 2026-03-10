import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    required List<File> images,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated.');
    }

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

  /// Retrieves a stream of rentals created by a specific user.
  static Stream<QuerySnapshot> getUserRentals(String uid) {
    return _firestore
        .collection('rentals')
        .where('ownerId', isEqualTo: uid)
        .snapshots();
  }

  /// Retrieves a stream of all rentals for client-side geospatial filtering.
  static Stream<QuerySnapshot> getNearbyCandidates() {
    return _firestore.collection('rentals').snapshots();
  }
}
