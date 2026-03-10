import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/services/rental_service.dart';
import 'package:rentals/services/user_service.dart';
import 'home_page.dart'; // Imports your AnimatedLikeButton

class NearMePage extends StatefulWidget {
  const NearMePage({super.key});

  @override
  State<NearMePage> createState() => _NearMePageState();
}

class _NearMePageState extends State<NearMePage> {
  double _selectedRadius = 5.0; // Default 5 km
  final List<double> _radiusOptions = [2.0, 5.0, 10.0, 20.0];

  double? _userLat;
  double? _userLng;
  bool _isFetchingLocation = true;
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationError = '';
    });

    // --- CHECK CACHE FIRST ---
    if (UserService.currentLat != null && UserService.currentLng != null) {
      setState(() {
        _userLat = UserService.currentLat;
        _userLng = UserService.currentLng;
        _isFetchingLocation = false;
      });
      return; // Skip GPS if cached
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError = 'Location services are disabled.';
            _isFetchingLocation = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _locationError = 'Location permission denied.';
              _isFetchingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError = 'Location permissions are permanently denied.';
            _isFetchingLocation = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      // --- STORE IN CACHE ---
      UserService.currentLat = position.latitude;
      UserService.currentLng = position.longitude;

      if (mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Failed to get location: $e';
          _isFetchingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF113F67),
        elevation: 0,
        title: const Text(
          "Rentals Near Me",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildRadiusSelector(),
          Expanded(child: _buildBodyContent()),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      color: const Color(0xFF113F67).withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Search Radius (km)",
            style: TextStyle(
              color: Color(0xFF113F67),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _radiusOptions.map((radius) {
              bool isSelected = _selectedRadius == radius;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRadius = radius;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF16BCE6) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF16BCE6)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    "${radius.toInt()} km",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isFetchingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF16BCE6)),
            SizedBox(height: 15),
            Text("Detecting your location..."),
          ],
        ),
      );
    }

    if (_locationError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 50, color: Colors.redAccent),
              const SizedBox(height: 15),
              Text(
                _locationError,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _getUserLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF113F67),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_userLat == null || _userLng == null) {
      return const Center(child: Text("Location not available. Please retry."));
    }

    // --- USING SERVICE INSTEAD OF DIRECT QUERY ---
    return StreamBuilder<QuerySnapshot>(
      stream: RentalService.getNearbyCandidates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No rentals available right now."));
        }

        // --- FILTERING LOGIC ---
        List<Map<String, dynamic>> nearbyItems = [];

        for (var doc in snapshot.data!.docs) {
          // 1. Create a mutable map from document data safely
          final data = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );

          // 2. Inject the Firestore document ID
          data['id'] = doc.id;

          if (data['latitude'] != null && data['longitude'] != null) {
            double itemLat = (data['latitude'] is num)
                ? (data['latitude'] as num).toDouble()
                : 0.0;
            double itemLng = (data['longitude'] is num)
                ? (data['longitude'] as num).toDouble()
                : 0.0;

            if (itemLat != 0.0 && itemLng != 0.0) {
              double distanceInMeters = Geolocator.distanceBetween(
                _userLat!,
                _userLng!,
                itemLat,
                itemLng,
              );

              double distanceInKm = distanceInMeters / 1000;

              if (distanceInKm <= _selectedRadius) {
                // Add the exact distance to the map so we can display it
                data['distance_away'] = distanceInKm;
                nearbyItems.add(data);
              }
            }
          }
        }

        // Sort items so the closest ones appear first
        nearbyItems.sort(
          (a, b) => (a['distance_away'] as double).compareTo(
            b['distance_away'] as double,
          ),
        );

        if (nearbyItems.isEmpty) {
          return Center(
            child: Text(
              "No items found within ${_selectedRadius.toInt()} km.\nTry increasing your search radius!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: nearbyItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.70, // Slightly taller to fit the distance text
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            return _buildDealCard(context, nearbyItems[index]);
          },
        );
      },
    );
  }

  // Exact same card from HomePage, with an added Distance tag and safe image handling
  Widget _buildDealCard(BuildContext context, Map<String, dynamic> deal) {
    String imageUrl = '';

    // Safety check for dynamic lists from Firestore
    if (deal['imageUrls'] != null) {
      if (deal['imageUrls'] is List && (deal['imageUrls'] as List).isNotEmpty) {
        imageUrl = deal['imageUrls'][0].toString();
      } else if (deal['imageUrls'] is String &&
          (deal['imageUrls'] as String).isNotEmpty) {
        imageUrl = deal['imageUrls'].toString();
      }
    }

    double distance = deal['distance_away'] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF113F67).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            height: 100,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              height: 100,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF16BCE6),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            height: 100,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF113F67).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnimatedLikeButton(
                        deal: deal,
                      ), // Reuses your Like Button
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal['title']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF113F67),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // --- NEW: Display the distance ---
                      Text(
                        "${distance.toStringAsFixed(1)} km away",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF16BCE6),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          "Rs. ${deal['price'] ?? ''}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF113F67),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductPage(productData: deal),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          width: 40,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF113F67),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/icons/rent_icon.png",
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF113F67),
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
