import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rentals/services/user_service.dart';
import 'package:rentals/views/product/product_page.dart';
import 'package:rentals/views/map/rental_map_marker_icon_factory.dart';
import 'package:rentals/widgets/app_network_image.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng _defaultLocation = LatLng(19.8762, 75.3433);
  static const double _previewCardHeight = 132;
  static const ClusterManagerId _rentalsClusterManagerId = ClusterManagerId(
    'rentals_cluster_manager',
  );

  GoogleMapController? _mapController;
  final RentalMapMarkerIconFactory _markerIconFactory =
      RentalMapMarkerIconFactory();
  final ValueNotifier<String?> _selectedRentalIdNotifier = ValueNotifier(null);
  late final ClusterManager _clusterManager;
  MapType _mapType = MapType.normal;
  BitmapDescriptor? _fallbackMarkerIcon;
  String _lastMarkerSignature = '';
  String _lastMarkerIconSignature = '';
  String _cachedMarkersSignature = '';
  List<_RentalMapEntry> _lastEntries = const <_RentalMapEntry>[];
  List<_RentalMapEntry> _cachedEntries = const <_RentalMapEntry>[];
  Set<Marker> _cachedMarkers = const <Marker>{};
  bool _markerRefreshQueued = false;
  QuerySnapshot? _lastEntriesSnapshot;

  @override
  void initState() {
    super.initState();
    _clusterManager = ClusterManager(
      clusterManagerId: _rentalsClusterManagerId,
      onClusterTap: _handleClusterTap,
    );
    _primeFallbackMarkerIcon();
  }

  @override
  void dispose() {
    _selectedRentalIdNotifier.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _openRentalItem(Map<String, dynamic> itemData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPage(productData: itemData),
      ),
    );
  }

  LatLng _preferredInitialTarget(List<_RentalMapEntry> entries) {
    final currentLat = UserService.currentLat;
    final currentLng = UserService.currentLng;
    if (currentLat != null && currentLng != null) {
      return LatLng(currentLat, currentLng);
    }

    if (entries.isNotEmpty) {
      return entries.first.position;
    }

    return _defaultLocation;
  }

  String _extractImageUrl(Map<String, dynamic> itemData) {
    final imageUrl = itemData['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }

    final imageUrls = itemData['imageUrls'];
    if (imageUrls is List && imageUrls.isNotEmpty) {
      final firstImage = imageUrls.first.toString().trim();
      if (firstImage.isNotEmpty) {
        return firstImage;
      }
    }

    if (imageUrls is String && imageUrls.trim().isNotEmpty) {
      return imageUrls.trim();
    }

    return '';
  }

  String _extractOwnerName(Map<String, dynamic> itemData) {
    final ownerName = itemData['ownerName']?.toString().trim() ?? '';
    if (ownerName.isNotEmpty) {
      return ownerName;
    }

    return 'Unknown Owner';
  }

  String _priceLabel(Map<String, dynamic> itemData) {
    final price = itemData['price']?.toString() ?? '0';
    final duration = itemData['duration']?.toString().trim() ?? '';
    if (duration.isEmpty) {
      return 'Rs. $price / day';
    }

    final normalizedDuration = duration.toLowerCase();
    if (normalizedDuration.startsWith('per ')) {
      return 'Rs. $price / ${normalizedDuration.substring(4)}';
    }

    return 'Rs. $price / $normalizedDuration';
  }

  List<_RentalMapEntry> _buildEntries(QuerySnapshot snapshot) {
    final entries = <_RentalMapEntry>[];

    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );
      data['id'] = doc.id;

      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      if (latitude == null ||
          longitude == null ||
          latitude.abs() > 90 ||
          longitude.abs() > 180) {
        continue;
      }

      entries.add(
        _RentalMapEntry(
          id: doc.id,
          data: data,
          position: LatLng(latitude, longitude),
        ),
      );
    }

    return entries;
  }

  List<_RentalMapEntry> _entriesForSnapshot(QuerySnapshot snapshot) {
    if (identical(_lastEntriesSnapshot, snapshot)) {
      return _cachedEntries;
    }

    _lastEntriesSnapshot = snapshot;
    _cachedEntries = _buildEntries(snapshot);
    _cachedMarkersSignature = '';
    return _cachedEntries;
  }

  _RentalMapEntry? _findEntryById(List<_RentalMapEntry> entries, String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }

    for (final entry in entries) {
      if (entry.id == id) {
        return entry;
      }
    }

    return null;
  }

  Future<void> _handleMarkerTap(_RentalMapEntry entry) async {
    _selectedRentalIdNotifier.value = entry.id;
    await _focusOnEntry(entry);
  }

  Future<void> _handleClusterTap(Cluster cluster) async {
    _selectedRentalIdNotifier.value = null;

    final controller = _mapController;
    if (controller == null) {
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(cluster.bounds, 88),
      );
    } catch (_) {
      final zoomLevel = await controller.getZoomLevel();
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: cluster.position,
            zoom: math.max(zoomLevel + 1.6, 14.2),
          ),
        ),
      );
    }
  }

  Future<void> _primeFallbackMarkerIcon() async {
    final fallbackMarkerIcon = await _markerIconFactory.fallbackDescriptor();
    if (!mounted) {
      return;
    }

    setState(() {
      _fallbackMarkerIcon = fallbackMarkerIcon;
    });
  }

  void _scheduleMarkerIconWarmup(List<_RentalMapEntry> entries) {
    if (_fallbackMarkerIcon == null || entries.isEmpty) {
      return;
    }

    final signature = _buildMarkerIconSignature(entries);
    if (signature == _lastMarkerIconSignature) {
      return;
    }

    _lastMarkerIconSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _warmMarkerIcons(entries);
    });
  }

  void _warmMarkerIcons(List<_RentalMapEntry> entries) {
    final queuedKeys = <String>{};
    for (final entry in entries) {
      final imageUrl = _extractImageUrl(entry.data);
      final cacheKey = _markerIconFactory.cacheKeyForImage(imageUrl);

      if (!queuedKeys.add(cacheKey) ||
          _markerIconFactory.cachedDescriptor(cacheKey) != null) {
        continue;
      }

      _markerIconFactory
          .loadDescriptor(imageUrl)
          .then((_) {
            _queueMarkerRefresh();
          })
          .catchError((_) {
            _queueMarkerRefresh();
          });
    }
  }

  void _queueMarkerRefresh() {
    if (_markerRefreshQueued || !mounted) {
      return;
    }

    _markerRefreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markerRefreshQueued = false;
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  Future<void> _focusOnEntry(_RentalMapEntry entry) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    try {
      final zoomLevel = await controller.getZoomLevel();
      final screenCoordinate = await controller.getScreenCoordinate(
        entry.position,
      );
      final adjustedTarget = await controller.getLatLng(
        ScreenCoordinate(x: screenCoordinate.x, y: screenCoordinate.y + 190),
      );

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: adjustedTarget,
            zoom: math.max(zoomLevel, 14.4),
          ),
        ),
      );
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: entry.position, zoom: 14.8),
        ),
      );
    }
  }

  Set<Marker> _buildMarkers(List<_RentalMapEntry> entries) {
    final fallbackMarkerIcon = _fallbackMarkerIcon;
    if (fallbackMarkerIcon == null) {
      return const <Marker>{};
    }

    final markerSignature =
        '${fallbackMarkerIcon.hashCode}'
        '|${_buildMarkerSignature(entries)}'
        '|${_buildMarkerIconSignature(entries)}';
    if (markerSignature == _cachedMarkersSignature) {
      return _cachedMarkers;
    }

    _cachedMarkers = entries.map((entry) {
      final imageUrl = _extractImageUrl(entry.data);
      final cacheKey = _markerIconFactory.cacheKeyForImage(imageUrl);
      final markerIcon =
          _markerIconFactory.cachedDescriptor(cacheKey) ?? fallbackMarkerIcon;

      return Marker(
        markerId: MarkerId(entry.id),
        position: entry.position,
        anchor: const Offset(0.5, 1.0),
        consumeTapEvents: true,
        clusterManagerId: _rentalsClusterManagerId,
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: entry.data['title']?.toString() ?? 'Rental Item',
          snippet: entry.data['location']?.toString(),
        ),
        onTap: () => _handleMarkerTap(entry),
      );
    }).toSet();
    _cachedMarkersSignature = markerSignature;
    return _cachedMarkers;
  }

  String _buildMarkerSignature(List<_RentalMapEntry> entries) {
    return entries
        .map(
          (entry) =>
              '${entry.id}:${entry.position.latitude.toStringAsFixed(5)},${entry.position.longitude.toStringAsFixed(5)}',
        )
        .join('|');
  }

  String _buildMarkerIconSignature(List<_RentalMapEntry> entries) {
    return entries
        .map(
          (entry) =>
              '${entry.id}:${_markerIconFactory.cacheKeyForImage(_extractImageUrl(entry.data))}',
        )
        .join('|');
  }

  Future<void> _fitMapToEntries(List<_RentalMapEntry> entries) async {
    final controller = _mapController;
    if (controller == null || entries.isEmpty) {
      return;
    }

    if (entries.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: entries.first.position, zoom: 15),
        ),
      );
      return;
    }

    double minLat = entries.first.position.latitude;
    double maxLat = entries.first.position.latitude;
    double minLng = entries.first.position.longitude;
    double maxLng = entries.first.position.longitude;

    for (final entry in entries.skip(1)) {
      minLat = math.min(minLat, entry.position.latitude);
      maxLat = math.max(maxLat, entry.position.latitude);
      minLng = math.min(minLng, entry.position.longitude);
      maxLng = math.max(maxLng, entry.position.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  void _scheduleMapFit(List<_RentalMapEntry> entries) {
    _lastEntries = entries;
    if (_mapController == null || entries.isEmpty) {
      return;
    }

    final signature = _buildMarkerSignature(entries);
    if (signature == _lastMarkerSignature) {
      return;
    }

    _lastMarkerSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _fitMapToEntries(entries);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _scheduleMapFit(_lastEntries);
  }

  Widget _buildSelectedRentalPreview(List<_RentalMapEntry> entries) {
    return ValueListenableBuilder<String?>(
      valueListenable: _selectedRentalIdNotifier,
      builder: (context, selectedRentalId, child) {
        final selectedEntry = _findEntryById(entries, selectedRentalId);
        final itemData = selectedEntry?.data;
        final hasSelection = itemData != null;

        return IgnorePointer(
          ignoring: !hasSelection,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            offset: hasSelection ? Offset.zero : const Offset(0, 1.2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: hasSelection ? 1 : 0,
              child: hasSelection
                  ? _RentalPreviewCard(
                      imageUrl: _extractImageUrl(itemData),
                      title: itemData['title']?.toString() ?? 'Rental Item',
                      priceLabel: _priceLabel(itemData),
                      ownerName: _extractOwnerName(itemData),
                      onTap: () => _openRentalItem(itemData),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingControls(List<_RentalMapEntry> entries) {
    return ValueListenableBuilder<String?>(
      valueListenable: _selectedRentalIdNotifier,
      builder: (context, selectedRentalId, child) {
        final bottomInset = selectedRentalId == null
            ? 0.0
            : _previewCardHeight + 18;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildFocusButton(entries),
          ),
        );
      },
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

          final entries = snapshot.hasData
              ? _entriesForSnapshot(snapshot.data!)
              : const <_RentalMapEntry>[];
          _scheduleMarkerIconWarmup(entries);
          final markers = _buildMarkers(entries);
          _scheduleMapFit(entries);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _preferredInitialTarget(entries),
                  zoom: 12.8,
                ),
                onMapCreated: _onMapCreated,
                mapType: _mapType,
                markers: markers,
                clusterManagers: {_clusterManager},
                buildingsEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                trafficEnabled: false,
                zoomControlsEnabled: false,
                onTap: (_) => _selectedRentalIdNotifier.value = null,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.map_outlined,
                                    color: Color(0xFF16BCE6),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entries.isEmpty
                                          ? 'No rentals with map coordinates yet'
                                          : '${entries.length} rentals available on the map',
                                      style: const TextStyle(
                                        color: Color(0xFF113F67),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildMapTypeToggle(),
                        ],
                      ),
                      const Spacer(),
                      _buildFloatingControls(entries),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: SafeArea(
                  top: false,
                  child: _buildSelectedRentalPreview(entries),
                ),
              ),
              if (entries.isEmpty)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Listings with saved latitude and longitude will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF113F67),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapTypeToggle() {
    return Material(
      elevation: 4,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMapTypeChip(label: 'Normal', mapType: MapType.normal),
            _buildMapTypeChip(label: 'Satellite', mapType: MapType.satellite),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeChip({required String label, required MapType mapType}) {
    final isSelected = _mapType == mapType;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _mapType = mapType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF113F67) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF113F67),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFocusButton(List<_RentalMapEntry> entries) {
    return Material(
      elevation: 4,
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: entries.isEmpty ? null : () => _fitMapToEntries(entries),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.center_focus_strong, color: Color(0xFF16BCE6)),
              SizedBox(width: 10),
              Text(
                'Show All Rentals',
                style: TextStyle(
                  color: Color(0xFF113F67),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RentalPreviewCard extends StatelessWidget {
  const _RentalPreviewCard({
    required this.imageUrl,
    required this.title,
    required this.priceLabel,
    required this.ownerName,
    required this.onTap,
  });

  final String imageUrl;
  final String title;
  final String priceLabel;
  final String ownerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          height: _MapPageState._previewCardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AppNetworkImage(
                    imageUrl: imageUrl,
                    width: 104,
                    height: double.infinity,
                    memCacheWidth: 640,
                    memCacheHeight: 800,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF113F67),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        priceLabel,
                        style: const TextStyle(
                          color: Color(0xFF16BCE6),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ownerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF113F67),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'View Item',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RentalMapEntry {
  const _RentalMapEntry({
    required this.id,
    required this.data,
    required this.position,
  });

  final String id;
  final Map<String, dynamic> data;
  final LatLng position;
}
