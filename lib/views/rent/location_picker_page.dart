import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:rentals/widgets/google_map_picker.dart';

class LocationPickerPage extends StatelessWidget {
  final LatLng? initialLocation;
  final String? initialLocationLabel;

  const LocationPickerPage({
    super.key,
    this.initialLocation,
    this.initialLocationLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF113F67),
        elevation: 0,
        title: const Text(
          "Select Location",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GoogleMapPicker(
        initialLatitude: initialLocation?.latitude,
        initialLongitude: initialLocation?.longitude,
        initialLocationLabel: initialLocationLabel,
        onLocationSelected: (selection) {
          Navigator.pop(context, selection);
        },
      ),
    );
  }
}
