import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_places_sdk/google_places_sdk.dart' as places;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GooglePlaceSuggestion {
  const GooglePlaceSuggestion({
    required this.placeId,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final String placeId;
  final String title;
  final String subtitle;
  final String description;
}

class LocationSelectionData {
  const LocationSelectionData({
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  final String location;
  final double latitude;
  final double longitude;

  LatLng get latLng => LatLng(latitude, longitude);
}

class GoogleMapsLocationService {
  GoogleMapsLocationService._();

  static const MethodChannel _channel = MethodChannel(
    'rentals/google_maps_api',
  );

  static String? _cachedApiKey;
  static places.GooglePlaces? _placesSdk;
  static String? _placesSdkApiKey;

  static Future<String?> getApiKey() async {
    final cachedApiKey = _cachedApiKey;
    if (cachedApiKey != null && cachedApiKey.isNotEmpty) {
      return cachedApiKey;
    }

    try {
      final apiKey = await _channel.invokeMethod<String>('getApiKey');
      final normalizedApiKey = apiKey?.trim() ?? '';
      if (normalizedApiKey.isNotEmpty) {
        _cachedApiKey = normalizedApiKey;
        return normalizedApiKey;
      }
    } catch (_) {
      // Gracefully fall back to manual map selection when a platform key
      // isn't available to the autocomplete helper.
    }

    return null;
  }

  static String coordinatesLabel({
    required double latitude,
    required double longitude,
  }) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  static Future<bool> hasLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<LocationSelectionData> getCurrentLocationSelection() async {
    final position = await _getCurrentPosition();
    final reverseGeocodedLocation = await reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return reverseGeocodedLocation ??
        LocationSelectionData(
          location: coordinatesLabel(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          latitude: position.latitude,
          longitude: position.longitude,
        );
  }

  static Future<List<GooglePlaceSuggestion>> autocomplete(String input) async {
    final query = input.trim();
    if (query.length < 2) {
      return const <GooglePlaceSuggestion>[];
    }

    final placesSdk = await _getPlacesSdk();
    if (placesSdk == null) {
      return const <GooglePlaceSuggestion>[];
    }

    try {
      final response = await placesSdk.getAutoCompletePredictions(
        query,
        placeTypes: const [places.PlaceType.geocode],
      );

      return response
          .map(
            (prediction) => GooglePlaceSuggestion(
              placeId: prediction.placeId ?? '',
              title: prediction.primaryText ?? '',
              subtitle: prediction.secondaryText ?? '',
              description:
                  prediction.fullName ??
                  prediction.primaryText ??
                  prediction.secondaryText ??
                  '',
            ),
          )
          .where((suggestion) => suggestion.placeId.trim().isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      throw Exception(
        'Could not fetch location suggestions. ${_normalizedErrorMessage(error)}',
      );
    }
  }

  static Future<LocationSelectionData?> fetchPlaceDetails(
    String placeId,
  ) async {
    final normalizedPlaceId = placeId.trim();
    if (normalizedPlaceId.isEmpty) {
      return null;
    }

    final placesSdk = await _getPlacesSdk();
    if (placesSdk == null) {
      return null;
    }

    try {
      final response = await placesSdk.fetchPlaceDetails(
        normalizedPlaceId,
        placeFields: const [
          places.PlaceField.address,
          places.PlaceField.latLng,
          places.PlaceField.name,
        ],
      );

      return _selectionFromPlace(response);
    } catch (error) {
      throw Exception(
        'Could not load the selected place. ${_normalizedErrorMessage(error)}',
      );
    }
  }

  static Future<LocationSelectionData?> geocodeAddress(String input) async {
    final query = input.trim();
    if (query.isEmpty) {
      return null;
    }

    try {
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isEmpty) {
        return null;
      }

      final location = locations.first;
      final reverseGeocodedLocation = await reverseGeocode(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      return reverseGeocodedLocation ??
          LocationSelectionData(
            location: query,
            latitude: location.latitude,
            longitude: location.longitude,
          );
    } catch (error) {
      throw Exception(
        'Could not search for that location. ${_normalizedErrorMessage(error)}',
      );
    }
  }

  static Future<LocationSelectionData?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      final firstPlacemark = placemarks.isNotEmpty ? placemarks.first : null;
      return LocationSelectionData(
        location: _labelFromPlacemark(
          firstPlacemark,
          latitude: latitude,
          longitude: longitude,
        ),
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return LocationSelectionData(
        location: coordinatesLabel(latitude: latitude, longitude: longitude),
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  static Future<places.GooglePlaces?> _getPlacesSdk() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    final cachedPlacesSdk = _placesSdk;
    if (cachedPlacesSdk != null && _placesSdkApiKey == apiKey) {
      return cachedPlacesSdk;
    }

    final googlePlaces = places.GooglePlaces();
    await googlePlaces.initialize(apiKey);
    _placesSdk = googlePlaces;
    _placesSdkApiKey = apiKey;
    return _placesSdk;
  }

  static Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please enable location services to continue.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  static LocationSelectionData? _selectionFromPlace(
    places.PlaceDetails? place,
  ) {
    final latLng = place?.latLng;
    if (latLng == null) {
      return null;
    }

    final latitude = latLng.lat;
    final longitude = latLng.lng;
    if (latitude == null || longitude == null) {
      return null;
    }

    return LocationSelectionData(
      location: _normalizedPlaceLabel(
        address: place?.address,
        displayName: place?.name,
        latitude: latitude,
        longitude: longitude,
      ),
      latitude: latitude,
      longitude: longitude,
    );
  }

  static String _normalizedPlaceLabel({
    String? address,
    String? displayName,
    required double latitude,
    required double longitude,
  }) {
    final normalizedAddress = address?.trim() ?? '';
    if (normalizedAddress.isNotEmpty) {
      return normalizedAddress;
    }

    final normalizedDisplayName = displayName?.trim() ?? '';
    if (normalizedDisplayName.isNotEmpty) {
      return normalizedDisplayName;
    }

    return coordinatesLabel(latitude: latitude, longitude: longitude);
  }

  static String _labelFromPlacemark(
    geocoding.Placemark? placemark, {
    required double latitude,
    required double longitude,
  }) {
    if (placemark == null) {
      return coordinatesLabel(latitude: latitude, longitude: longitude);
    }

    final rawParts = <String?>[
      placemark.name,
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ];

    final uniqueParts = <String>[];
    for (final part in rawParts) {
      final normalizedPart = part?.trim() ?? '';
      if (normalizedPart.isEmpty) {
        continue;
      }

      final alreadyAdded = uniqueParts.any(
        (existingPart) =>
            existingPart.toLowerCase() == normalizedPart.toLowerCase(),
      );
      if (!alreadyAdded) {
        uniqueParts.add(normalizedPart);
      }
    }

    if (uniqueParts.isEmpty) {
      return coordinatesLabel(latitude: latitude, longitude: longitude);
    }

    return uniqueParts.join(', ');
  }

  static String _normalizedErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
