import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentals/models/transaction_model.dart';

class TransactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Get Items User is Renting (User is the Renter) ---
  static Stream<List<TransactionModel>> getUserRents() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('transactions')
        .where('renterId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // --- Get Items User is Hosting (User is the Host) ---
  static Stream<List<TransactionModel>> getUserHosts() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('transactions')
        .where('hostId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
