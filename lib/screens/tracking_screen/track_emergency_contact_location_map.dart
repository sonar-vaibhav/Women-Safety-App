import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeguardher_flutter_app/models/alert_with_contact_model.dart';
import '../../models/alert_model.dart';
import '../../providers.dart';

class TrackEmergencyContactLocationMap extends ConsumerStatefulWidget {
  final String panickedPersonName;
  final Alert panickedPersonAlertDetails;
  final String panickedPersonProfilePic;

  const TrackEmergencyContactLocationMap({
    super.key,
    required this.panickedPersonName,
    required this.panickedPersonAlertDetails,
    required this.panickedPersonProfilePic,
  });

  @override
  _TrackEmergencyContactLocationMapState createState() =>
      _TrackEmergencyContactLocationMapState();
}

class _TrackEmergencyContactLocationMapState
    extends ConsumerState<TrackEmergencyContactLocationMap> {
  GoogleMapController? mapController;
  LatLng? senderLocation;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();

    // Get sender's current location from alert
    senderLocation = LatLng(
      widget.panickedPersonAlertDetails.userLocationEnd.latitude,
      widget.panickedPersonAlertDetails.userLocationEnd.longitude,
    );
    
    // Create marker immediately
    if (senderLocation != null) {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('senderLocation'),
          position: senderLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '${widget.panickedPersonName}\'s Location',
          ),
        ),
      );
    }
  }

  void _createMarker() {
    if (senderLocation != null) {
      markers.clear();
      
      // Red marker for sender's current location
      markers.add(
        Marker(
          markerId: const MarkerId('senderLocation'),
          position: senderLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '${widget.panickedPersonName}\'s Location',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to real-time location updates
    ref.listen<AsyncValue<List<AlertWithContact>>>(
      emergencyContactAlertsStreamProvider,
          (previous, next) {
        next.whenData((alerts) {
          try {
            var alert = alerts.firstWhere(
              (a) => a.alert.alertId == widget.panickedPersonAlertDetails.alertId,
            );

            if (alert != null) {
              LatLng newLocation = LatLng(
                alert.alert.userLocationEnd.latitude,
                alert.alert.userLocationEnd.longitude,
              );

              setState(() {
                senderLocation = newLocation;
                _createMarker();

                // Animate camera to new location
                if (mapController != null) {
                  mapController!.animateCamera(
                    CameraUpdate.newLatLng(newLocation),
                  );
                }
              });
            }
          } catch (e) {
            // Alert not found in list
          }
        });
      },
    );

    bool hasValidLocation = senderLocation != null &&
        (senderLocation!.latitude != 0 || senderLocation!.longitude != 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.panickedPersonName} - Location'),
        centerTitle: true,
      ),
      body: !hasValidLocation
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
              GoogleMap(
                  key: ValueKey(markers.length),
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                    mapController!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: senderLocation!,
                          zoom: 15.0,
                        ),
                      ),
                    );
                  },
                  initialCameraPosition: CameraPosition(
                    target: senderLocation ?? const LatLng(0, 0),
                    zoom: 15.0,
                  ),
                  markers: markers,
                  zoomControlsEnabled: true,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  left: 10,
                  child: _buildAlertInfo(),
                ),
              ],
            ),
    );
  }

  // Widget to display panicked person's info
  Widget _buildAlertInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: widget.panickedPersonProfilePic.isNotEmpty &&
                    !widget.panickedPersonProfilePic.startsWith('assets/')
                ? NetworkImage(widget.panickedPersonProfilePic)
                : const AssetImage('assets/placeholders/default_profile_pic.png')
            as ImageProvider,
            radius: 30,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.panickedPersonName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Shared their live location with you.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
