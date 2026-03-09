class TransactionModel {
  final String id;
  final String renterId;
  final String hostId;
  final String rentalId;
  final String itemName;
  final String itemImage;
  final String price;
  final String date;
  final String status;
  final double? rating;

  // UI Specific Fields
  final String renterName;
  final String renterEmail;
  final String renterImage;
  final String hostName;

  TransactionModel({
    required this.id,
    required this.renterId,
    required this.hostId,
    required this.rentalId,
    required this.itemName,
    required this.itemImage,
    required this.price,
    required this.date,
    required this.status,
    this.rating,
    required this.renterName,
    required this.renterEmail,
    required this.renterImage,
    required this.hostName,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data, String id) {
    return TransactionModel(
      id: id,
      renterId: data['renterId'] ?? '',
      hostId: data['hostId'] ?? '',
      rentalId: data['rentalId'] ?? '',
      itemName: data['itemName'] ?? 'Unknown Item',
      itemImage: data['itemImage'] ?? '',
      price: data['price']?.toString() ?? '0',
      date: data['date'] ?? 'N/A',
      status: data['status'] ?? 'Pending',
      rating: data['rating'] != null
          ? double.tryParse(data['rating'].toString())
          : null,
      renterName: data['renterName'] ?? 'Unknown User',
      renterEmail: data['renterEmail'] ?? 'No email provided',
      renterImage: data['renterImage'] ?? '',
      hostName: data['hostName'] ?? 'Unknown Host',
    );
  }
}
