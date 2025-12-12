import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../controllers/socket_controller.dart';
import '../controllers/order_controller.dart';

class LiveTrackingPage extends StatefulWidget {
  final String orderId;
  final int orderidNameForShow;
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
    required this.orderidNameForShow,
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
    final prefs = await SharedPreferences.getInstance();
    bool alreadyAllowed = prefs.getBool("location_permission_given") ?? false;

    // If already allowed before → Do NOT show popup
    if (alreadyAllowed) {
      _getCurrentUserLocation();
      return;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
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
                Navigator.pop(context); // User exits screen
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                // Save preference so popup won't show again
                await prefs.setBool("location_permission_given", true);

                _getCurrentUserLocation(); // Proceed
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
        '&mode=driving'
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Live Tracking",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),

        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // _______________________________
          // 🔹 ORDER HEADER CARD
          // _______________________________

          _modernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.receipt_long,
                    color: Colors.deepPurple, size: 30),
                const SizedBox(height: 8),

                Text(
                  "Order #${widget.orderidNameForShow}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  "Status: ${_statusText(_liveOrderStatus)}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // _______________________________
          // 🔹 MAID INFO
          // _______________________________

          _modernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_pin_circle,
                    size: 30, color: Colors.blue),
                const SizedBox(height: 6),

                const Text(
                  "Maid Details",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                _infoTile("Name", _liveMaidName ?? "Not Assigned"),
                _infoTile("Phone", _liveMaidPhone ?? "N/A"),
                _infoTile("Email", _liveMaidEmail ?? "N/A"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // _______________________________
          // 🔹 ETA + DISTANCE TILE
          // _______________________________

          _modernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.directions_run,
                    size: 30, color: Colors.teal),
                const SizedBox(height: 6),

                const Text(
                  "Tracking Information",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                _infoTile("Distance", _distance ?? "Calculating..."),
                _infoTile("Estimated Time", _estimatedTime ?? "Calculating..."),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _updateRoute,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Refresh",style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // _______________________________
          // 🔹 GOOGLE MAP Modern Card
          // _______________________________

          Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: size.height * 0.55,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_currentUserLat!, _currentUserLng!),
                  zoom: 13,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _updateMap();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

// 🔥 Modern Card Wrapper
  Widget _modernCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

// 🔥 Info Tile
  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          Text(value,
              style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

}