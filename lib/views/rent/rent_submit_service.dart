import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RentSubmitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

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
    try {
      // 1. Get the current user UID
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User is not logged in. Cannot upload rental item.");
      }

      // 2. Fetch the user profile to attach owner details to the rental document
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      String ownerName = 'Unknown User';
      String ownerImage = '';

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        ownerName = userData['name'] ?? 'Unknown User';
        ownerImage = userData['profileImageUrl'] ?? '';
      }

      // 3. Create a new document reference first to generate a unique rentalId
      final DocumentReference rentalDocRef = _firestore
          .collection('rentals')
          .doc();
      final String rentalId = rentalDocRef.id;

      // 4. Upload each image to Firebase Storage
      List<String> uploadedImageUrls = [];
      for (int i = 0; i < images.length; i++) {
        File file = images[i];
        String fileName = 'image_$i.jpg';

        // Path organized by: rental_images/{userId}/{rentalId}/image_0.jpg
        Reference storageRef = _storage
            .ref()
            .child('rental_images')
            .child(user.uid)
            .child(rentalId)
            .child(fileName);

        await storageRef.putFile(file);
        String downloadUrl = await storageRef.getDownloadURL();
        uploadedImageUrls.add(downloadUrl);
      }

      // 5. Save the complete rental document in Firestore
      await rentalDocRef.set({
        'id': rentalId,
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
        'imageUrls': uploadedImageUrls,
        'userId': user.uid,
        'ownerName': ownerName,
        'ownerImage': ownerImage,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception("Firestore/Storage error: ${e.message}");
    } catch (e) {
      throw Exception("An unexpected error occurred: ${e.toString()}");
    }
  }
}
