import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rentals/services/user_service.dart';

class FavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ValueNotifier<Set<String>> _favoriteIdsNotifier =
      ValueNotifier<Set<String>>(<String>{});

  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _favoriteIdsSubscription;
  static String? _favoriteIdsUserId;

  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  static ValueListenable<Set<String>> favoriteIdsListenable() {
    _ensureFavoriteIdsTracking();
    return _favoriteIdsNotifier;
  }

  static String getRentalId(Map<String, dynamic> rentalData) {
    return rentalData['id']?.toString() ??
        rentalData['rentalId']?.toString() ??
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

  static void _ensureFavoriteIdsTracking() {
    _authSubscription ??= _auth.authStateChanges().listen((user) {
      _bindFavoriteIdsForUser(user?.uid);
    });

    _bindFavoriteIdsForUser(getCurrentUserId());
  }

  static void _bindFavoriteIdsForUser(String? uid) {
    if (_favoriteIdsUserId == uid) {
      return;
    }

    _favoriteIdsSubscription?.cancel();
    _favoriteIdsSubscription = null;
    _favoriteIdsUserId = uid;

    if (uid == null || uid.isEmpty) {
      _favoriteIdsNotifier.value = <String>{};
      return;
    }

    _favoriteIdsSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
          final favoriteIds = snapshot.docs
              .map((doc) {
                final data = doc.data();
                return data['rentalId']?.toString() ??
                    data['id']?.toString() ??
                    doc.id;
              })
              .where((id) => id.isNotEmpty)
              .toSet();

          _favoriteIdsNotifier.value = favoriteIds;
        });
  }

  static void _applyLocalFavoriteState(String rentalId, bool isFavorite) {
    if (rentalId.isEmpty || rentalId == 'unknown_id') {
      return;
    }

    final updatedIds = Set<String>.from(_favoriteIdsNotifier.value);
    if (isFavorite) {
      updatedIds.add(rentalId);
    } else {
      updatedIds.remove(rentalId);
    }
    _favoriteIdsNotifier.value = updatedIds;
  }

  static Future<void> toggleFavorite(Map<String, dynamic> rentalData) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception("User not logged in.");

    await UserService.ensureCurrentUserCanPerformWrite();

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
      _applyLocalFavoriteState(rentalId, false);
    } else {
      final favoriteData = Map<String, dynamic>.from(rentalData);
      favoriteData['rentalId'] = rentalId;
      favoriteData['favoritedAt'] = FieldValue.serverTimestamp();
      await docRef.set(favoriteData);
      _applyLocalFavoriteState(rentalId, true);
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
