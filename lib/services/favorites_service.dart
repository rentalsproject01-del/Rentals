import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  static String getRentalId(Map<String, dynamic> rentalData) {
    return rentalData['id']?.toString() ??
        rentalData['rentalId']?.toString() ??
        rentalData['title']?.toString() ??
        'unknown_id';
  }

  static Stream<bool> isFavoriteStream(String rentalId) {
    final uid = getCurrentUserId();
    if (uid == null || rentalId.isEmpty || rentalId == 'unknown_id') {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(rentalId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  static Future<void> toggleFavorite(Map<String, dynamic> rentalData) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception("User not logged in.");

    final rentalId = getRentalId(rentalData);
    if (rentalId.isEmpty || rentalId == 'unknown_id') {
      throw Exception("Invalid rental id.");
    }

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(rentalId);

    final docSnap = await docRef.get();

    if (docSnap.exists) {
      await docRef.delete();
    } else {
      final favoriteData = Map<String, dynamic>.from(rentalData);
      favoriteData['rentalId'] = rentalId;
      favoriteData['favoritedAt'] = FieldValue.serverTimestamp();
      await docRef.set(favoriteData);
    }
  }

  static Stream<List<Map<String, dynamic>>> getFavoriteItems() {
    final uid = getCurrentUserId();
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('favoritedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = data['id'] ?? doc.id;
            return data;
          }).toList();
        });
  }
}
