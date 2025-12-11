import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../controllers/socket_controller.dart';
import '../controllers/order_controller.dart';

class LiveTrackingPage extends StatefulWidget {
  final String orderId;
  final double maidLat;
  final double maidLng;
  final String maidName;
  final String maidPhone;
  final String maidEmail;
  final double userLat;
  final double userLng;
  final int orderStatus;

  const LiveTrackingPage({
    super.key,
    required this.orderId,
    required this.maidLat,
    required this.maidLng,
    required this.maidName,
    required this.maidPhone,
    required this.maidEmail,
    required this.userLat,
    required this.userLng,
    required this.orderStatus,
  });

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  double? _liveMaidLat;
  double? _liveMaidLng;
  String? _liveMaidName;
  String? _liveMaidPhone;
  String? _liveMaidEmail;
  int? _liveOrderStatus;
  double? _currentUserLat;
  double? _currentUserLng;
  String? _distance;
  String? _estimatedTime;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _routeUpdateTimer;

  // Google Maps API key (same as MapScreen)
  static const String _googleApiKey = 'AIzaSyCcppZWLo75ylSQvsR-bTPZLEFEEec5nrY';

  @override
  void initState() {
    super.initState();
    _liveMaidLat = widget.maidLat;
    _liveMaidLng = widget.maidLng;
    _liveMaidName = widget.maidName;
    _liveMaidPhone = widget.maidPhone;
    _liveMaidEmail = widget.maidEmail;
    _liveOrderStatus = widget.orderStatus;
    _currentUserLat = widget.userLat;
    _currentUserLng = widget.userLng;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _showPermissionDisclaimer(); // Show popup first

      _setupSocketListener();
      _setupInitialData();

      _routeUpdateTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
        _updateRoute();
      });
    });
  }

  @override
  void dispose() {
    _routeUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _setupSocketListener() {
    final socketController = Provider.of<SocketController>(context, listen: false);
    socketController.onMaidStartedOrder = (orderId, maidInfo) {
      if (orderId == widget.orderId && mounted) {
        setState(() {
          _liveMaidLat = maidInfo['maidLat'] is String
              ? double.tryParse(maidInfo['maidLat']) ?? _liveMaidLat
              : (maidInfo['maidLat'] as num?)?.toDouble() ?? _liveMaidLat;
          _liveMaidLng = maidInfo['maidLng'] is String
              ? double.tryParse(maidInfo['maidLng']) ?? _liveMaidLng
              : (maidInfo['maidLng'] as num?)?.toDouble() ?? _liveMaidLng;
          _liveMaidName = maidInfo['maidName'] ?? _liveMaidName;
          _liveMaidPhone = maidInfo['maidPhone'] ?? _liveMaidPhone;
          _liveMaidEmail = maidInfo['maidEmail'] ?? _liveMaidEmail;
          _liveOrderStatus = _statusCodeFromServer(maidInfo['status']);
        });
        _updateRoute();
        debugPrint('📍 Updated maid location for order $orderId: $_liveMaidLat, $_liveMaidLng');
      }
    };
  }

  int _statusCodeFromServer(dynamic status) {
    if (status is int) {
      if ([0, 1, 2, 5, 7].contains(status)) return status;
      return 5; // Default to Started
    }
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'cancelled':
          return 0;
        case 'placed':
          return 1;
        case 'accepted':
          return 2;
        case 'started':
          return 5;
        case 'completed':
          return 7;
        default:
          return 5;
      }
    }
    return 5; // Default to Started
  }

  Future<void> _showPermissionDisclaimer() async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: const [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text("Location Permission"),
            ],
          ),
          content: const Text(
            "We need access to your location ONLY to show live tracking of your maid.\n\n"
                "We do NOT store or misuse your personal location data.",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // User backs out
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _getCurrentUserLocation(); // Start permission process
              },
              child: const Text("Allow"),
            ),
          ],
        );
      },
    );
  }


  Future<void> _getCurrentUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentUserLat = position.latitude;
          _currentUserLng = position.longitude;
          _isLoading = false;
        });
        await _updateRoute();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRoute() async {
    if (_currentUserLat == null ||
        _currentUserLng == null ||
        _liveMaidLat == null ||
        _liveMaidLng == null) {
      setState(() {
        _errorMessage = 'Invalid location data';
      });
      return;
    }

    // Validate locations
    if (_currentUserLat == 0.0 ||
        _currentUserLng == 0.0 ||
        _liveMaidLat == 0.0 ||
        _liveMaidLng == 0.0) {
      setState(() {
        _errorMessage = 'Invalid location coordinates (0.0, 0.0)';
      });
      return;
    }

    final origin = '$_liveMaidLat,$_liveMaidLng';
    final destination = '$_currentUserLat,$_currentUserLng';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin'
        '&destination=$destination'
        '&mode=walking' // Use walking mode for maid
        '&key=$_googleApiKey';

    debugPrint("➡️ Directions API URL: $url");
    debugPrint("📍 Origin: $origin, Destination: $destination");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          setState(() {
            _distance = leg['distance']['text'];
            _estimatedTime = leg['duration']['text'];
            _polylineCoordinates =
                _decodePolyline(route['overview_polyline']['points']);
            _errorMessage = null;
          });
          _updateMap();
        } else {
          setState(() {
            _errorMessage = 'Directions API error: ${data['status']}';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching route: $e';
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _setupInitialData() {
    _markers.clear();
    _polylines.clear();

    if (_currentUserLat != null &&
        _currentUserLng != null &&
        _currentUserLat != 0 &&
        _currentUserLng != 0) {
      _markers.add(Marker(
        markerId: const MarkerId("user"),
        position: LatLng(_currentUserLat!, _currentUserLng!),
        infoWindow: const InfoWindow(title: "You"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (_liveMaidLat != null &&
        _liveMaidLng != null &&
        _liveMaidLat != 0 &&
        _liveMaidLng != 0) {
      _markers.add(Marker(
        markerId: const MarkerId("maid"),
        position: LatLng(_liveMaidLat!, _liveMaidLng!),
        infoWindow: InfoWindow(title: _liveMaidName ?? "Maid"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));

      if (_polylineCoordinates.isNotEmpty) {
        _polylines.add(Polyline(
          polylineId: const PolylineId("route"),
          points: _polylineCoordinates,
          color: Colors.blueAccent, // Match MapScreen's polyline color
          width: 5,
        ));
      }
    }

    if (mounted) setState(() {});
  }

  void _updateMap() {
    _setupInitialData();
    if (_mapController != null &&
        _markers.length >= 2 &&
        _currentUserLat != null &&
        _currentUserLng != null &&
        _liveMaidLat != null &&
        _liveMaidLng != null) {
      final latitudes = _markers.map((m) => m.position.latitude).toList();
      final longitudes = _markers.map((m) => m.position.longitude).toList();

      final bounds = LatLngBounds(
        southwest: LatLng(latitudes.reduce(math.min), longitudes.reduce(math.min)),
        northeast: LatLng(latitudes.reduce(math.max), longitudes.reduce(math.max)),
      );

      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else if (_currentUserLat != null &&
        _currentUserLng != null &&
        _currentUserLat != 0 &&
        _currentUserLng != 0) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(_currentUserLat!, _currentUserLng!), 12),
      );
    }
  }

  String _statusText(int? status) {
    switch (status) {
      case 0:
        return "Cancelled";
      case 1:
        return "Placed";
      case 2:
        return "Accepted";
      case 5:
        return "Started";
      case 7:
        return "Completed";
      default:
        return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Live Tracking - ${widget.orderId}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16, color: Colors.red),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order Info
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        "Order ID: ${widget.orderId}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.timelapse, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        "Status: ${_statusText(_liveOrderStatus)}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Maid Info
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Maid Details",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ListTile(
                    leading:
                    const Icon(Icons.account_circle, color: Colors.purple),
                    title: Text(_liveMaidName ?? "Not Assigned"),
                    subtitle: const Text("Name"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: Text(_liveMaidPhone ?? "N/A"),
                    subtitle: const Text("Phone"),
                  ),
                  ListTile(
                    leading:
                    const Icon(Icons.email, color: Colors.redAccent),
                    title: Text(_liveMaidEmail ?? "N/A"),
                    subtitle: const Text("Email"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Distance & ETA
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.map, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        "Tracking Information",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ListTile(
                    leading:
                    const Icon(Icons.route, color: Colors.blueAccent),
                    title: Text(_distance ?? "Calculating..."),
                    subtitle: const Text("Distance"),
                  ),
                  ListTile(
                    leading:
                    const Icon(Icons.access_time, color: Colors.orange),
                    title: Text(_estimatedTime ?? "Calculating..."),
                    subtitle: const Text("Estimated Time"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                    onPressed: _updateRoute,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Map
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            clipBehavior: Clip.antiAlias,
            elevation: 6,
            child: SizedBox(
              height: size.height * 0.5,
              child: GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  _updateMap();
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (_currentUserLat ?? 37.7749 + _liveMaidLat! ?? 37.7749) / 2,
                    (_currentUserLng ?? -122.4194 + _liveMaidLng! ?? -122.4194) / 2,
                  ),
                  zoom: 12,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _markers,
                polylines: _polylines,
                zoomControlsEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: true,
                tiltGesturesEnabled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}