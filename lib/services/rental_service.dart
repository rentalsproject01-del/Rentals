import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RentalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- 1. Upload Rental ---
  static Future<void> uploadRental({
    required String title,
    required String description,
    required double price,
    required String category,
    required List<File> images,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // 1. Get the current user UID
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User is not logged in. Cannot upload rental item.");
      }

      // 2. Fetch the user profile from 'users' collection
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception(
          "User profile not found. Please complete account setup.",
        );
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final String ownerName = userData['name'] ?? 'Unknown User';
      final String ownerImage = userData['profileImageUrl'] ?? '';

      // 3. Create a new document reference first to generate a rentalId
      final DocumentReference rentalDocRef = _firestore
          .collection('rentals')
          .doc();
      final String rentalId = rentalDocRef.id;

      // 4. Upload each image to Firebase Storage
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        try {
          Reference ref = _storage.ref().child(
            'rental_images/$rentalId/image_$i.jpg',
          );

          await ref.putFile(images[i]);
          String downloadUrl = await ref.getDownloadURL();
          imageUrls.add(downloadUrl);
        } catch (e) {
          throw Exception("Failed to upload image $i: $e");
        }
      }

      // 5 & 6. Save the rental document in Firestore
      await rentalDocRef.set({
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'ownerId': user.uid,
        'ownerName': ownerName,
        'ownerImage': ownerImage,
        'imageUrls': imageUrls,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception("Firestore/Storage error: ${e.message}");
    } catch (e) {
      // Re-throw previously caught custom exceptions or unexpected errors
      throw Exception(e.toString());
    }
  }

  // --- 2. Get All Rentals ---
  static Stream<QuerySnapshot> getAllRentals() {
    return _firestore
        .collection('rentals')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- 3. Get Rentals By User ---
  static Stream<QuerySnapshot> getUserRentals(String uid) {
    return _firestore
        .collection('rentals')
        .where('ownerId', isEqualTo: uid)
        .snapshots();
  }

  // --- 4. Get Nearby Candidates (Limited Size) ---
  static Stream<QuerySnapshot> getNearbyCandidates() {
    return _firestore
        .collection('rentals')
        .orderBy('createdAt', descending: true)
        .limit(200) // Limits query size to prevent huge reads
        .snapshots();
  }
}
