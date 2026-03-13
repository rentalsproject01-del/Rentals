import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentals/models/home_banner.dart';

class HomeBannerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<HomeBanner>> watchActiveBanners() {
    return _firestore
        .collection('banners')
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
          final banners = snapshot.docs
              .map(HomeBanner.fromDocument)
              .where((banner) => banner.isActive && banner.hasUsableImage)
              .toList();

          banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return banners;
        });
  }
}
