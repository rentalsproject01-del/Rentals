import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentals/services/user_service.dart';
import 'package:rentals/models/transaction_model.dart';

class TransactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Set<String> _blockingStatuses = {
    'pending',
    'accepted',
    'approved',
    'active',
    'ongoing',
  };

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
  }

  static int _extractSortMillis(Map<String, dynamic> data) {
    if (data['createdAt'] is Timestamp) {
      return (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
    }
    if (data['acceptedAt'] is Timestamp) {
      return (data['acceptedAt'] as Timestamp).millisecondsSinceEpoch;
    }
    if (data['rejectedAt'] is Timestamp) {
      return (data['rejectedAt'] as Timestamp).millisecondsSinceEpoch;
    }
    return 0;
  }

  static Future<void> createRentalRequest({
    required Map<String, dynamic> rentalData,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated.');

    final String uid = currentUser.uid;
    final userProfile = await UserService.getCurrentUserProfile();

    if (userProfile == null) {
      throw Exception('User profile not found.');
    }

    final String rentalId = rentalData['id']?.toString() ?? '';
    final String hostId =
        rentalData['ownerId']?.toString() ??
        rentalData['hostId']?.toString() ??
        '';

    if (rentalId.isEmpty) {
      throw Exception('Invalid item data. Cannot send request.');
    }

    if (hostId.isEmpty) {
      throw Exception('Seller information is missing.');
    }

    if (uid == hostId) {
      throw Exception('You cannot send a rental request to yourself.');
    }

    // Check if the user has ANY existing request for this item, regardless of status.
    final existingReq = await _firestore
        .collection('transactions')
        .where('renterId', isEqualTo: uid)
        .where('rentalId', isEqualTo: rentalId)
        .get();

    if (existingReq.docs.isNotEmpty) {
      throw Exception('You have already sent a request for this item.');
    }

    final now = DateTime.now();
    final dateString = _formatDate(now);

    String itemImage = '';
    final dynamic imageUrls = rentalData['imageUrls'];

    if (imageUrls is List && imageUrls.isNotEmpty) {
      itemImage = imageUrls.first.toString();
    } else if (imageUrls is String && imageUrls.isNotEmpty) {
      itemImage = imageUrls;
    }

    await _firestore.collection('transactions').add({
      'renterId': uid,
      'hostId': hostId,
      'rentalId': rentalId,
      'itemName': rentalData['title'] ?? 'Unknown Item',
      'itemImage': itemImage,
      'price': rentalData['price']?.toString() ?? '0',
      'date': dateString,
      'status': 'Pending',
      'renterName': userProfile['name'] ?? 'Unknown Renter',
      'renterEmail': userProfile['email'] ?? currentUser.email ?? '',
      'renterImage': userProfile['profileImageUrl'] ?? '',
      'hostName': rentalData['ownerName'] ?? 'Unknown Owner',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<TransactionModel>> getUserRents() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('renterId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.toList();

          docs.sort((a, b) {
            final millisA = _extractSortMillis(a.data());
            final millisB = _extractSortMillis(b.data());

            // Descending order (newest first)
            return millisB.compareTo(millisA);
          });

          return docs.map((doc) {
            return TransactionModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  static Stream<List<TransactionModel>> getUserHosts() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('hostId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.toList();

          docs.sort((a, b) {
            final millisA = _extractSortMillis(a.data());
            final millisB = _extractSortMillis(b.data());

            // Descending order (newest first)
            return millisB.compareTo(millisA);
          });

          return docs.map((doc) {
            return TransactionModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  static Future<void> acceptRentalRequest({
    required String transactionId,
    required int rentalDays,
  }) async {
    if (rentalDays <= 0) {
      throw Exception('Rental days must be greater than 0.');
    }

    final now = DateTime.now();
    final endDate = now.add(Duration(days: rentalDays));

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'Accepted',
      'rentalDays': rentalDays,
      'acceptedAt': FieldValue.serverTimestamp(),
      'startAt': Timestamp.fromDate(now),
      'endAt': Timestamp.fromDate(endDate),
    });
  }

  static Future<void> rejectRentalRequest({
    required String transactionId,
  }) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'Rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getTransactionsForRental(String rentalId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('rentalId', isEqualTo: rentalId)
        .get();

    return snapshot.docs;
  }

  static Future<bool> hasBlockingTransactionsForRental(String rentalId) async {
    final docs = await getTransactionsForRental(rentalId);

    for (final doc in docs) {
      final status = doc.data()['status']?.toString().trim().toLowerCase() ?? '';
      if (_blockingStatuses.contains(status)) {
        return true;
      }
    }

    return false;
  }
}
