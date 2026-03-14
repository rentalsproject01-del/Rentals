import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBanner {
  final String id;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;
  final String? storagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HomeBanner({
    required this.id,
    required this.imageUrl,
    required this.isActive,
    required this.sortOrder,
    this.storagePath,
    this.createdAt,
    this.updatedAt,
  });

  factory HomeBanner.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return HomeBanner(
      id: document.id,
      imageUrl: data['imageUrl']?.toString().trim() ?? '',
      isActive: _parseBool(data['isActive']),
      sortOrder: _parseSortOrder(data['sortOrder'] ?? data['order']),
      storagePath: data['storagePath']?.toString().trim(),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  String get preferredImageSource {
    final trimmedStoragePath = storagePath?.trim() ?? '';
    return trimmedStoragePath.isNotEmpty ? trimmedStoragePath : imageUrl;
  }

  bool get hasUsableImage => preferredImageSource.isNotEmpty;

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1';
  }

  static int _parseSortOrder(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }

    return null;
  }
}
