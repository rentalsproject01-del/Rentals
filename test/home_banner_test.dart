import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentals/models/home_banner.dart';

void main() {
  group('HomeBanner', () {
    test('prefers storagePath for rendering when available', () {
      const banner = HomeBanner(
        id: 'banner-1',
        imageUrl: 'https://example.com/legacy-banner.png',
        storagePath: 'banners/banner-1/current.png',
        isActive: true,
        sortOrder: 0,
      );

      expect(banner.preferredImageSource, 'banners/banner-1/current.png');
      expect(banner.hasUsableImage, isTrue);
    });

    test('falls back to legacy order when sortOrder is missing', () {
      final document = _FakeBannerDocumentSnapshot(
        id: 'banner-legacy',
        data: <String, dynamic>{
          'imageUrl': 'https://example.com/banner.png',
          'isActive': true,
          'order': 3,
        },
      );

      final banner = HomeBanner.fromDocument(document);

      expect(banner.sortOrder, 3);
      expect(banner.preferredImageSource, 'https://example.com/banner.png');
    });
  });
}

class _FakeBannerDocumentSnapshot
    extends DocumentSnapshot<Map<String, dynamic>> {
  _FakeBannerDocumentSnapshot({
    required this.id,
    required Map<String, dynamic> data,
  }) : _data = data;

  final Map<String, dynamic> _data;

  @override
  final String id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
