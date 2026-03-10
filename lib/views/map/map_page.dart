import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rentals/views/product/product_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  // Default location if no markers are found (e.g., your city center)
  final LatLng _defaultLocation = const LatLng(19.8762, 75.3433);

  // --- SHOW ITEM PREVIEW (BOTTOM SHEET) ---
  void _showItemPreview(BuildContext context, Map<String, dynamic> itemData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String imageUrl = '';
        if (itemData['imageUrls'] != null &&
            (itemData['imageUrls'] as List).isNotEmpty) {
          imageUrl = itemData['imageUrls'][0];
        }

        return GestureDetector(
          onTap: () {
            // 1. Close the bottom sheet
            Navigator.pop(context);
            // 2. Open the full Product Page with the item's data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductPage(productData: itemData),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // --- IMAGE ---
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF16BCE6),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                const SizedBox(width: 15),

                // --- DETAILS ---
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemData['title'] ?? 'Rental Item',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF113F67),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itemData['subcategory'] ?? itemData['category'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Rs. ${itemData['price'] ?? '0'}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16BCE6),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF113F67),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "View",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF113F67),
        elevation: 0,
        title: const Text(
          "Map View",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rentals').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Marker> markers = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;

              // Safely extract coordinates if they exist
              double? lat;
              double? lng;

              if (data.containsKey('latitude') &&
                  data.containsKey('longitude')) {
                lat = (data['latitude'] is num)
                    ? (data['latitude'] as num).toDouble()
                    : null;
                lng = (data['longitude'] is num)
                    ? (data['longitude'] as num).toDouble()
                    : null;
              }

              // Only create a marker if valid coordinates exist
              if (lat != null && lng != null) {
                markers.add(
                  Marker(
                    point: LatLng(lat, lng),
                    width: 55, // Increased slightly for the image avatar
                    height: 55,
                    child: GestureDetector(
                      onTap: () => _showItemPreview(context, data),
                      child: Builder(
                        builder: (context) {
                          // 1. Safely check for images in this item's data
                          final List<dynamic>? imageUrls = data['imageUrls'];
                          final bool hasImage =
                              imageUrls != null && imageUrls.isNotEmpty;

                          // 2. Fallback if no image exists
                          if (!hasImage) {
                            return const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 45,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            );
                          }

                          // 3. Custom circular image marker
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFF16BCE6),
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: imageUrls[0],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF16BCE6),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return const Icon(
                                    Icons.location_on,
                                    color: Colors.redAccent,
                                    size: 35,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
            }
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rentals.app', // Required by OSM
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
