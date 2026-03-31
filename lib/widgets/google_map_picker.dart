import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rentals/services/google_maps_location_service.dart';

class GoogleMapPicker extends StatefulWidget {
  const GoogleMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationLabel,
    required this.onLocationSelected,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationLabel;
  final ValueChanged<LocationSelectionData> onLocationSelected;

  @override
  State<GoogleMapPicker> createState() => _GoogleMapPickerState();
}

class _GoogleMapPickerState extends State<GoogleMapPicker> {
  static const double _initialZoom = 15.2;
  static const LatLng _fallbackTarget = LatLng(19.8762, 75.3433);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  List<GooglePlaceSuggestion> _suggestions = const <GooglePlaceSuggestion>[];
  LatLng? _selectedLocation;
  LocationSelectionData? _selectedSelection;
  LatLng _cameraTarget = _fallbackTarget;
  MapType _mapType = MapType.normal;
  bool _hasLocationPermission = false;
  bool _isLocatingUser = false;
  bool _isSearching = false;
  bool _isResolvingSelection = false;
  bool _hasShownAutocompleteError = false;
  int _searchRequestId = 0;
  int _selectionRequestId = 0;

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(() {
      if (!mounted) {
        return;
      }

      setState(() {});
    });

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      final initialSelection = LocationSelectionData(
        location: widget.initialLocationLabel?.trim().isNotEmpty == true
            ? widget.initialLocationLabel!.trim()
            : GoogleMapsLocationService.coordinatesLabel(
                latitude: widget.initialLatitude!,
                longitude: widget.initialLongitude!,
              ),
        latitude: widget.initialLatitude!,
        longitude: widget.initialLongitude!,
      );
      _selectedSelection = initialSelection;
      _selectedLocation = initialSelection.latLng;
      _cameraTarget = initialSelection.latLng;
      _setSearchText(initialSelection.location);
    }

    _syncLocationPermissionState();
    _resolveInitialSelectionLabel();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _syncLocationPermissionState() async {
    final hasPermission =
        await GoogleMapsLocationService.hasLocationPermission();
    if (!mounted) {
      return;
    }

    setState(() {
      _hasLocationPermission = hasPermission;
    });
  }

  Future<void> _resolveInitialSelectionLabel() async {
    final initialSelection = _selectedSelection;
    final initialLocationLabel = widget.initialLocationLabel?.trim() ?? '';
    if (initialSelection == null || initialLocationLabel.isNotEmpty) {
      return;
    }

    await _updateSelectionFromCoordinates(
      initialSelection.latLng,
      moveCamera: false,
      showLookupFailure: false,
    );
  }

  Future<void> _moveCamera(LatLng target, {double zoom = _initialZoom}) async {
    _cameraTarget = target;
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _moveCamera(_cameraTarget);
  }

  void _setSearchText(String value) {
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _clearSuggestions() {
    if (!mounted) {
      return;
    }

    setState(() {
      _suggestions = const <GooglePlaceSuggestion>[];
      _isSearching = false;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();
    if (query.length < 2) {
      _clearSuggestions();
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() {
      _isSearching = true;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final suggestions = await GoogleMapsLocationService.autocomplete(query);
        if (!mounted ||
            requestId != _searchRequestId ||
            _searchController.text.trim() != query) {
          return;
        }

        setState(() {
          _suggestions = suggestions;
          _isSearching = false;
        });
        _hasShownAutocompleteError = false;
      } catch (error) {
        if (!mounted || requestId != _searchRequestId) {
          return;
        }

        setState(() {
          _suggestions = const <GooglePlaceSuggestion>[];
          _isSearching = false;
        });

        if (!_hasShownAutocompleteError) {
          _hasShownAutocompleteError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
          );
        }
      }
    });
  }

  Future<void> _selectSuggestion(GooglePlaceSuggestion suggestion) async {
    _searchFocusNode.unfocus();
    _clearSuggestions();

    try {
      final selection = await GoogleMapsLocationService.fetchPlaceDetails(
        suggestion.placeId,
      );
      if (!mounted) {
        return;
      }

      if (selection == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load that place. Try another result.'),
          ),
        );
        return;
      }

      await _applySelection(selection, moveCamera: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _searchBySubmittedText(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      return;
    }

    _searchFocusNode.unfocus();
    _clearSuggestions();

    try {
      final selection = await GoogleMapsLocationService.geocodeAddress(query);
      if (!mounted) {
        return;
      }

      if (selection == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No matching location found for that search.'),
          ),
        );
        return;
      }

      await _applySelection(selection, moveCamera: true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _pickMyLocation() async {
    if (_isLocatingUser) {
      return;
    }

    setState(() {
      _isLocatingUser = true;
    });

    try {
      final selection =
          await GoogleMapsLocationService.getCurrentLocationSelection();
      if (!mounted) {
        return;
      }

      await _applySelection(selection, moveCamera: true);
      setState(() {
        _hasLocationPermission = true;
        _isLocatingUser = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLocatingUser = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _applySelection(
    LocationSelectionData selection, {
    required bool moveCamera,
  }) async {
    setState(() {
      _selectedSelection = selection;
      _selectedLocation = selection.latLng;
      _cameraTarget = selection.latLng;
      _isResolvingSelection = false;
      _suggestions = const <GooglePlaceSuggestion>[];
      _isSearching = false;
      _setSearchText(selection.location);
    });

    if (moveCamera) {
      await _moveCamera(selection.latLng);
    }
  }

  Future<void> _updateSelectionFromCoordinates(
    LatLng position, {
    required bool moveCamera,
    bool showLookupFailure = true,
  }) async {
    final fallbackSelection = LocationSelectionData(
      location: GoogleMapsLocationService.coordinatesLabel(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final requestId = ++_selectionRequestId;

    setState(() {
      _selectedLocation = position;
      _selectedSelection = fallbackSelection;
      _cameraTarget = position;
      _isResolvingSelection = true;
      _suggestions = const <GooglePlaceSuggestion>[];
      _setSearchText(fallbackSelection.location);
    });

    if (moveCamera) {
      await _moveCamera(position);
    }

    try {
      final resolvedSelection = await GoogleMapsLocationService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted || requestId != _selectionRequestId) {
        return;
      }

      setState(() {
        final selection = resolvedSelection ?? fallbackSelection;
        _selectedSelection = selection;
        _isResolvingSelection = false;
        _setSearchText(selection.location);
      });
    } catch (error) {
      if (!mounted || requestId != _selectionRequestId) {
        return;
      }

      setState(() {
        _selectedSelection = fallbackSelection;
        _isResolvingSelection = false;
      });

      if (showLookupFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Address lookup unavailable right now. Coordinates will still be saved.',
            ),
          ),
        );
      }
    }
  }

  void _confirmSelection() {
    final selection = _selectedSelection;
    if (selection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first.')),
      );
      return;
    }

    widget.onLocationSelected(selection);
  }

  Set<Marker> get _markers {
    final selectedLocation = _selectedLocation;
    if (selectedLocation == null) {
      return const <Marker>{};
    }

    return <Marker>{
      Marker(
        markerId: const MarkerId('selected_location'),
        position: selectedLocation,
        draggable: true,
        onDragEnd: (updatedPosition) {
          _updateSelectionFromCoordinates(updatedPosition, moveCamera: false);
        },
        infoWindow: const InfoWindow(title: 'Selected location'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final selectedSelection = _selectedSelection;
    final mediaQuery = MediaQuery.of(context);
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _cameraTarget,
            zoom: _initialZoom,
          ),
          mapType: _mapType,
          onMapCreated: _onMapCreated,
          markers: _markers,
          myLocationEnabled: _hasLocationPermission,
          myLocationButtonEnabled: false,
          buildingsEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: false,
          trafficEnabled: false,
          zoomControlsEnabled: false,
          onTap: (position) {
            _searchFocusNode.unfocus();
            _updateSelectionFromCoordinates(position, moveCamera: false);
          },
        ),
        Positioned.fill(
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSearchSection(),
                      if (!keyboardVisible) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildHintCard()),
                            const SizedBox(width: 12),
                            _buildMapTypeToggle(),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!keyboardVisible)
                  Positioned(
                    right: 16,
                    bottom: 180,
                    child: _buildFloatingActionButton(),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: keyboardVisible ? mediaQuery.viewInsets.bottom + 12 : 24,
                  child: _buildSelectionCard(
                    selectedSelection,
                    compact: keyboardVisible,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    final hasSuggestions = _suggestions.isNotEmpty;
    final showSuggestionsPanel =
        _isSearching ||
        hasSuggestions ||
        (_searchFocusNode.hasFocus &&
            _searchController.text.trim().length >= 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: _searchBySubmittedText,
            decoration: InputDecoration(
              hintText: 'Search for an area, landmark, or address',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF113F67)),
              suffixIcon: _buildSearchSuffix(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (showSuggestionsPanel) ...[
          const SizedBox(height: 10),
          Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _buildSuggestionsBody(),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSearchSuffix() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF16BCE6),
          ),
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return null;
    }

    return IconButton(
      icon: const Icon(Icons.close, color: Colors.grey),
      onPressed: () {
        _searchController.clear();
        _clearSuggestions();
      },
    );
  }

  Widget _buildSuggestionsBody() {
    if (_isSearching && _suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF16BCE6),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Searching places...',
                style: TextStyle(
                  color: Color(0xFF113F67),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Text(
          'No suggestions found yet. Keep typing or search directly.',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.place_outlined, color: Color(0xFF16BCE6)),
          title: Text(
            suggestion.title.isNotEmpty
                ? suggestion.title
                : suggestion.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF113F67),
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            suggestion.subtitle.isNotEmpty
                ? suggestion.subtitle
                : suggestion.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }

  Widget _buildHintCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: const Row(
        children: [
          Icon(Icons.touch_app_rounded, color: Color(0xFF16BCE6), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search, tap the map, or use current location.',
              style: TextStyle(
                color: Color(0xFF113F67),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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

  Widget _buildFloatingActionButton() {
    return Material(
      elevation: 4,
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isLocatingUser ? null : _pickMyLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLocatingUser)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF16BCE6),
                  ),
                )
              else
                const Icon(Icons.my_location, color: Color(0xFF16BCE6)),
              const SizedBox(width: 10),
              const Text(
                'Pick My Location',
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

  Widget _buildSelectionCard(
    LocationSelectionData? selection, {
    bool compact = false,
  }) {
    final coordinatesText = selection == null
        ? 'No location selected yet'
        : '${selection.latitude.toStringAsFixed(6)}, ${selection.longitude.toStringAsFixed(6)}';

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: compact ? 150 : 260),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 18,
              compact ? 14 : 18,
              compact ? 14 : 18,
              compact ? 14 : 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: compact ? 36 : 42,
                      width: compact ? 36 : 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16BCE6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(compact ? 12 : 14),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: const Color(0xFF16BCE6),
                        size: compact ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: compact ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selection?.location ?? 'Select a place to continue',
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF113F67),
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 14 : 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coordinatesText,
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                              fontSize: compact ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 14),
                if (_isResolvingSelection) ...[
                  Row(
                    children: [
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF16BCE6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Confirming the selected address...',
                          style: TextStyle(
                            color: const Color(0xFF113F67),
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 14),
                ] else if (!compact)
                  const Text(
                    'You can refine it by dragging the pin or tapping another spot on the map.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                SizedBox(height: compact ? 10 : 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16BCE6),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: compact ? 12 : 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: selection == null ? null : _confirmSelection,
                    child: Text(
                      'Use this location',
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
