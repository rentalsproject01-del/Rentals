import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentals/models/home_banner.dart';

class HomeBannerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<HomeBanner>> watchActiveBanners() {
    return _firestore.collection('banners').snapshots().map((snapshot) {
      final banners = snapshot.docs
          .map(HomeBanner.fromDocument)
          .where((banner) => banner.isActive && banner.hasUsableImage)
          .toList();

      banners.sort(_compareBanners);
      return banners;
    });
  }

  static int _compareBanners(HomeBanner a, HomeBanner b) {
    final sortComparison = a.sortOrder.compareTo(b.sortOrder);
    if (sortComparison != 0) {
      return sortComparison;
    }

    final createdComparison = _compareDates(a.createdAt, b.createdAt);
    if (createdComparison != 0) {
      return createdComparison;
    }

    return a.id.compareTo(b.id);
  }

  static int _compareDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }

    return a.compareTo(b);
  }
}
