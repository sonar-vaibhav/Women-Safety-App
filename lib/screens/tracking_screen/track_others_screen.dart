import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants/colors.dart';
import '../../widgets/custom_widgets/track_others_app_bar.dart';
import '../home_screen/home_screen.dart';
import 'custom_marker.dart';
import 'networking.dart';
import '../../providers.dart';
import '../../models/alert_model.dart';

class TrackOthersScreen extends ConsumerStatefulWidget {
  const TrackOthersScreen({
    super.key,
    required this.panickedPersonName,
    required this.panickedPersonProfilePic,
    required this.panickedPersonSafetyCode,
    required this.panickedPersonAlertDetails,
  });

  final String panickedPersonName;
  final String panickedPersonProfilePic;
  final String panickedPersonSafetyCode;
  final Alert panickedPersonAlertDetails;

  @override
  ConsumerState<TrackOthersScreen> createState() => _TrackOthersScreenState();
}

class _TrackOthersScreenState extends ConsumerState<TrackOthersScreen> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  late LatLng destination;
  bool shownOnce = false;

  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polyLines = {};
  final Set<Marker> _markers = {};

  LocationData? currentLocationOfTheUser;
  bool loading = true;
  CustomMarker customMarker = CustomMarker();

  @override
  void initState() {
    super.initState();
    // Initialize destination from alert details
    destination = LatLng(
      widget.panickedPersonAlertDetails.userLocationEnd.latitude,
      widget.panickedPersonAlertDetails.userLocationEnd.longitude,
    );
    // Add initial sender marker
    _addInitialSenderMarker();
    getCurrentUserLocation();
  }

  // Add sender's marker immediately with simple red marker
  Future<void> _addInitialSenderMarker() async {
    try {
      setState(() {
        // Remove any existing destination marker
        _markers.removeWhere((marker) => marker.markerId.value == 'destination');
        
        // Add simple RED marker for sender's location
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: "${widget.panickedPersonName}'s Location (PANIC ALERT)",
              snippet: "Tap to see details",
            ),
          ),
        );
      });
      
      print("✅ Added red marker at: ${destination.latitude}, ${destination.longitude}");
    } catch (e) {
      print("❌ Error adding initial sender marker: $e");
    }
  }

  Future<void> createAndUpdateCustomMarker() async {
    if (currentLocationOfTheUser == null) return;

    try {
      setState(() {
        // Remove old destination marker
        _markers.removeWhere((marker) => marker.markerId.value == 'destination');
        
        // Add simple RED marker for sender's location
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: "${widget.panickedPersonName}'s Location (PANIC ALERT)",
              snippet: "Tap to see details",
            ),
          ),
        );
      });
      
      print("✅ Updated red marker at: ${destination.latitude}, ${destination.longitude}");
    } catch (e) {
      print("❌ Error updating custom marker: $e");
    }
  }

  Future<void> createAndUpdateSourceMarker() async {
    if (currentLocationOfTheUser == null) return;

    final userProfileAsyncValue = ref.watch(userStreamProvider);

    userProfileAsyncValue.when(
      data: (userProfile) async {
        final profilePicUrl = userProfile?.profilePic ?? 'assets/placeholders/default_profile_pic.png';

        final center = LatLng(
          currentLocationOfTheUser!.latitude!,
          currentLocationOfTheUser!.longitude!,
        );

        BitmapDescriptor customSourceMarkerIcon = await customMarker
            .createCustomTeardropMarker(profilePicUrl, const Color(0xFF6393F2));

        setState(() {
          _markers.removeWhere((marker) => marker.markerId.value == 'source');
          _markers.add(
            Marker(
              markerId: const MarkerId('source'),
              position: center,
              icon: customSourceMarkerIcon,
              infoWindow: const InfoWindow(
                title: "Source",
              ),
            ),
          );
        });
      },
      loading: () {
        // Handle loading state if necessary
      },
      error: (error, stackTrace) {
        // Handle error state if necessary
        print('Error fetching user profile: $error');
      },
    );
  }

  Future<void> getCurrentUserLocation() async {
    Location location = Location();

    currentLocationOfTheUser = await location.getLocation();

    setState(() {
      loading = false;
    });

    // ✅ Await all async operations in sequence
    await setMarkers();
    await createAndUpdateSourceMarker();
    await getRouteData();

    location.onLocationChanged.listen((newLocation) {
      if (currentLocationOfTheUser == null ||
          (currentLocationOfTheUser!.latitude != newLocation.latitude ||
              currentLocationOfTheUser!.longitude != newLocation.longitude)) {
        currentLocationOfTheUser = newLocation;
        setMarkers();
        createAndUpdateSourceMarker();
        getRouteData();
        // Removed _goToUserLocation() - keep camera on sender's location
        setState(() {});
      }
    });
  }

  Future<void> setMarkers() async {
    if (currentLocationOfTheUser != null) {
      // ✅ Don't clear ALL markers - preserve destination marker
      // Only remove source and danger markers
      _markers.removeWhere((marker) => 
          marker.markerId.value == "current_location" || 
          marker.markerId.value.startsWith('danger_'));

      try {
        // Fetch the user's profile picture URL
        final userProfileAsyncValue = ref.watch(userStreamProvider);

        await userProfileAsyncValue.when(
          data: (userProfile) async {
            final profilePicUrl = userProfile?.profilePic ?? 'https://firebasestorage.googleapis.com/v0/b/safeguardher-app.appspot.com/o/profile_pics%2F01719958727%2F1000007043.png?alt=media&token=34a85510-d1e2-40bd-b84b-5839bef880bc';

            BitmapDescriptor customSourceMarkerIcon = await customMarker.createCustomTeardropMarker(
                profilePicUrl, const Color(0xFF6393F2));

            _markers.add(
              Marker(
                markerId: const MarkerId("current_location"),
                icon: customSourceMarkerIcon,
                position: LatLng(
                  currentLocationOfTheUser!.latitude!,
                  currentLocationOfTheUser!.longitude!,
                ),
                infoWindow: const InfoWindow(
                  title: "You are here",
                ),
              ),
            );

            final alertsAsyncValue = ref.watch(emergencyContactAlertsStreamProvider);
            await alertsAsyncValue.when(
              data: (alerts) async {
                final alert = alerts.isNotEmpty ? alerts.first : null;
                if (alert != null) {
                  destination = LatLng(
                    alert.alert.userLocationEnd.latitude,
                    alert.alert.userLocationEnd.longitude,
                  );

                  await createAndUpdateCustomMarker();
                }

                final unsafePlacesAsyncValue = ref.watch(unsafePlacesStreamProvider);
                await unsafePlacesAsyncValue.when(
                  data: (unsafePlaces) async {
                    int i = 0;
                    for (final place in unsafePlaces) {
                      final placeLocation = LatLng(place.location.latitude, place.location.longitude);
                      final dangerMarkerIcon = await customMarker.createDangerMarker();
                      final marker = Marker(
                        markerId: MarkerId('danger_$i'),
                        position: placeLocation,
                        icon: dangerMarkerIcon,
                        infoWindow: InfoWindow(
                          title: place.type,
                          snippet: place.description,
                        ),
                      );
                      ++i;
                      _markers.add(marker);
                    }
                  },
                  loading: () => null,
                  error: (error, stack) {
                    print("Error fetching unsafe places: $error");
                    return null;
                  },
                );

                // ✅ Call setState() after all markers are added
                setState(() {});

                if (alert?.alert.isActive == null && shownOnce == false) {
                  shownOnce = true;
                  _showInactiveAlertDialog();
                }
              },
              error: (Object error, StackTrace stackTrace) {
                print("Error fetching emergency contact alerts: $error");
                return null;
              },
              loading: () => null,
            );
          },
          error: (Object error, StackTrace stackTrace) {
            print("Error fetching user profile: $error");
            return null;
          },
          loading: () => null,
        );
      } catch (e) {
        print("Error in setMarkers: $e");
      }
    }
  }


  Future<void> getRouteData() async {
    if (currentLocationOfTheUser != null) {
      NetworkHelper network = NetworkHelper(
        startLat: currentLocationOfTheUser!.latitude!,
        startLng: currentLocationOfTheUser!.longitude!,
        endLat: destination.latitude,
        endLng: destination.longitude,
      );

      try {
        var data = await network.getData();

        if (data != null && data['features'] != null && data['features'].isNotEmpty) {
          List<dynamic> coordinates = data['features'][0]['geometry']['coordinates'];
          polylineCoordinates.clear();

          for (var point in coordinates) {
            polylineCoordinates.add(LatLng(point[1], point[0]));
          }

          if (polylineCoordinates.isNotEmpty) {
            setPolyLines();
          }
        } else {
          print("Invalid response structure or empty features.");
        }
      } catch (e) {
        print("Error: $e");
      }
    }
  }

  void setPolyLines() {
    Polyline polyline = Polyline(
      polylineId: const PolylineId("route"),
      points: polylineCoordinates,
      color: Colors.blue,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      geodesic: false,
      jointType: JointType.round,
    );

    polyLines.clear();
    polyLines.add(polyline);
    setState(() {});
  }

  Future<void> _goToUserLocation() async {
    // Changed to go to sender's location instead of receiver's location
    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: destination,
          zoom: 15.0,
        ),
      ),
    );
  }

  void _showInactiveAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${widget.panickedPersonName} is saved!', style:
            const TextStyle(fontSize: 17), textAlign: TextAlign.center,),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  'Return to Home',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: TrackOthersAppBar(
        panickedPersonName: widget.panickedPersonName,
        userEndLocation: GeoPoint(
          destination.latitude,
          destination.longitude
        ),
        currentLocation: GeoPoint(
          currentLocationOfTheUser?.latitude ?? 0.0,
          currentLocationOfTheUser?.longitude ?? 0.0,
        ),
      ),

      body: loading
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: destination,
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              // Move camera to destination after map is created
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(destination, 15),
              );
            },
            markers: _markers,
            polylines: polyLines,
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Safe Code: ${widget.panickedPersonSafetyCode}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight
                    .bold, fontSize: 14),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 30,
            child: GestureDetector(
              onTap: _goToUserLocation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}