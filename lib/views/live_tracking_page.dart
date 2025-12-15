import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/socket_controller.dart';

class LiveTrackingPage extends StatefulWidget {
  final String orderId;
  final int orderidNameForShow;
  final double maidLat;
  final double maidLng;
  final String maidName;
  final String maidPhone;
  final double orderLat;
  final double orderLng;
  final int orderStatus;

  const LiveTrackingPage({
    super.key,
    required this.orderId,
    required this.orderidNameForShow,
    required this.maidLat,
    required this.maidLng,
    required this.maidName,
    required this.maidPhone,
    required this.orderLat,
    required this.orderLng,
    required this.orderStatus,
  });

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final SocketController _socket = SocketController();
  LatLng? _lastSocketPos;
  bool _reached = false;
  String _storageKey(String orderId) => "maid_live_$orderId";


  GoogleMapController? _map;
  BitmapDescriptor? _bikeIcon;

  LatLng? _maidPos;
  late LatLng _orderPos;

  double _bearing = 0;
  String _distanceText = "--";
  String _etaText = "--";
  bool _showArrival = false;

  DateTime? _lastRouteUpdate;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  static const String _googleKey = "AIzaSyCcppZWLo75ylSQvsR-bTPZLEFEEec5nrY";



  bool _isMaidOnline = false;
  DateTime? _lastSocketTime;
  Timer? _offlineTimer;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _isMaidOnline = false;
    _startOfflineWatcher();

    _orderPos = LatLng(widget.orderLat, widget.orderLng);

    if (widget.maidLat != 0 && widget.maidLng != 0) {
      _maidPos = LatLng(widget.maidLat, widget.maidLng);
    }

    debugPrint("🟢 LiveTracking INIT → order=${widget.orderId}");
    debugPrint("📍 Order=$_orderPos  Maid=$_maidPos");

    _loadBikeIcon();
    _loadSavedLocation();

    _socket.connect();
    _socket.onLiveTracking = _handleLiveTracking;
  }


  Future<void> _saveLiveLocation(
      double lat,
      double lng, {
        bool reached = false,
      }) async {

    final prefs = await SharedPreferences.getInstance();

    final data = {
      "lat": lat,
      "lng": lng,
      "reached": reached,
      "time": DateTime.now().toIso8601String(),
    };

    await prefs.setString(
      _storageKey(widget.orderId),
      jsonEncode(data),
    );

    debugPrint("💾 LOCATION SAVED LOCALLY → $data");
  }
  void _startOfflineWatcher() {
    _offlineTimer?.cancel();

    _offlineTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_lastSocketTime == null) return;

      final diff =
          DateTime.now().difference(_lastSocketTime!).inSeconds;

      if (diff > 30 && _isMaidOnline && !_reached) {
        debugPrint("🔴 MAID OFFLINE (no socket update)");

        setState(() {
          _isMaidOnline = false;
        });
      }
    });
  }


  // ------------------------------------------------------------
  // SOCKET CALLBACK (🔥 FIXED)
  // ------------------------------------------------------------
  void _handleLiveTracking(String orderId, Map<String, dynamic> data) async {

    _lastSocketTime = DateTime.now();

    if (!_isMaidOnline) {
      debugPrint("🟢 MAID IS NOW ONLINE");
    }

    _isMaidOnline = true;

    if (!mounted) return;
    if (orderId != widget.orderId) return;

    final lat = (data['maidLat'] as num).toDouble();
    final lng = (data['maidLng'] as num).toDouble();
    final newPos = LatLng(lat, lng);

    debugPrint("📡 SOCKET UPDATE RECEIVED → $newPos");

    // --------------------------------------------------
    // SAME LOCATION CHECK (BUT DO NOT RETURN ❌)
    // --------------------------------------------------
    final isSameLocation = _lastSocketPos != null &&
        _lastSocketPos!.latitude == newPos.latitude &&
        _lastSocketPos!.longitude == newPos.longitude;

    if (isSameLocation) {
      debugPrint("⚠️ SAME LOCATION RECEIVED (still updating UI)");
    } else {
      debugPrint("🟢 NEW LOCATION DETECTED");
      debugPrint("📍 OLD=$_lastSocketPos");
      debugPrint("📍 NEW=$newPos");
    }

    _lastSocketPos = newPos;

    // --------------------------------------------------
    // DISTANCE CALCULATION
    // --------------------------------------------------
    final km = _haversineDistance(newPos, _orderPos);
    final meters = (km * 1000).round();

    debugPrint("📏 DISTANCE = $meters meters");

    _distanceText =
    km < 1 ? "$meters m" : "${km.toStringAsFixed(1)} km";
    _etaText = _calculateEta(km);

    // --------------------------------------------------
    // REACHED STATE
    // --------------------------------------------------
    if (meters <= 30 && !_reached) {
      _reached = true;

      // ✅ STEP 5 (YAHAN)
      _isMaidOnline = false;
      _offlineTimer?.cancel();

      _showArrival = false;
      _etaText = "Reached";
      _distanceText = "0 m";

      await _saveLiveLocation(lat, lng, reached: true);

      _showReachedMessage();

      debugPrint("🏁 MAID REACHED DESTINATION");

      setState(() {});
      return;
    }



    // --------------------------------------------------
    // ARRIVING SOON STATE
    // --------------------------------------------------
    if (meters <= 150 && !_showArrival && !_reached) {
      _showArrival = true;
      debugPrint("🚨 ARRIVING IN 2 MINS");
    }

    // --------------------------------------------------
    // MARKER UPDATE (even if same location)
    // --------------------------------------------------
    if (_maidPos != null) {
      _bearing = _calculateBearing(_maidPos!, newPos);
      _animateBezier(_maidPos!, newPos);
    } else {
      _maidPos = newPos;
      _updateMap();
    }

    // --------------------------------------------------
    // ROUTE UPDATE (throttled)
    // --------------------------------------------------
    _updateRouteThrottled();

    await _saveLiveLocation(lat, lng);

    debugPrint("✅ UI UPDATED FROM SOCKET\n");
  }
  void _showReachedMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "🏁 Reached at destination. Your maid has arrived.",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }


  // ------------------------------------------------------------
  // BIKE ICON (SIZE FIXED)
  // ------------------------------------------------------------
  Future<void> _loadBikeIcon() async {
    final byteData =
    await rootBundle.load("assets/imagesforscreen/motorcycle_2050744.png");
    final codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: 70,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);

    _bikeIcon = BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
    if (mounted) {
      setState(() {});
      if (_maidPos != null) {
        _updateMap();
      }
    }

  }

  // ------------------------------------------------------------
  // ROUTE UPDATE
  // ------------------------------------------------------------
  void _updateRouteThrottled() {
    if (_maidPos == null) return;

    final km = _haversineDistance(_maidPos!, _orderPos);

    if (km <= 0.3) {
      _polylines.clear();
      setState(() {});
      return;
    }

    if (_lastRouteUpdate != null &&
        DateTime.now().difference(_lastRouteUpdate!).inSeconds < 15) return;

    _lastRouteUpdate = DateTime.now();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${_maidPos!.latitude},${_maidPos!.longitude}"
        "&destination=${_orderPos.latitude},${_orderPos.longitude}"
        "&mode=driving&key=$_googleKey";

    final res = await http.get(Uri.parse(url));
    final json = jsonDecode(res.body);

    if (json['status'] != "OK") return;

    final points = json['routes'][0]['overview_polyline']['points'];
    final decoded = _decodePolyline(points);

    debugPrint("🧭 Route updated → points=${decoded.length}");

    _polylines
      ..clear()
      ..add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: decoded,
          color: Colors.blue,
          width: 5,
        ),
      );

    setState(() {});
  }

  // ------------------------------------------------------------
  // SMOOTH MARKER MOVE
  // ------------------------------------------------------------
  void _animateBezier(LatLng start, LatLng end) {
    const steps = 20;
    int i = 0;

    Timer.periodic(const Duration(milliseconds: 40), (t) {
      i++;
      final p = i / steps;

      final lat = start.latitude +
          (end.latitude - start.latitude) * (p * p * (3 - 2 * p));
      final lng = start.longitude +
          (end.longitude - start.longitude) * (p * p * (3 - 2 * p));

      _maidPos = LatLng(lat, lng);
      _updateMap();

      if (i >= steps) t.cancel();
    });
  }

  // ------------------------------------------------------------
  // MAP UPDATE
  // ------------------------------------------------------------
  void _updateMap() {
    _markers.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId("order"),
        position: _orderPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    if (_maidPos != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("maid"),
          position: _maidPos!,
          rotation: _bearing,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: _bikeIcon!,
        ),
      );
    }

    if (_map != null && _maidPos != null) {
      _map!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              math.min(_maidPos!.latitude, _orderPos.latitude),
              math.min(_maidPos!.longitude, _orderPos.longitude),
            ),
            northeast: LatLng(
              math.max(_maidPos!.latitude, _orderPos.latitude),
              math.max(_maidPos!.longitude, _orderPos.longitude),
            ),
          ),
          80,
        ),
      );
    }

    if (mounted) setState(() {});
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  String _calculateEta(double km) {
    const speed = 25;
    final mins = (km / speed * 60).round();
    return mins <= 1 ? "1 min" : "$mins mins";
  }

  double _haversineDistance(LatLng a, LatLng b) {
    const R = 6371;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return 2 * R * math.asin(math.sqrt(h));
  }

  double _calculateBearing(LatLng s, LatLng e) {
    final lat1 = s.latitude * math.pi / 180;
    final lat2 = e.latitude * math.pi / 180;
    final dLng = (e.longitude - s.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> pts = [];
    int i = 0, lat = 0, lng = 0;

    while (i < encoded.length) {
      int b, shift = 0, res = 0;
      do {
        b = encoded.codeUnitAt(i++) - 63;
        res |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (res & 1) != 0 ? ~(res >> 1) : (res >> 1);

      shift = 0;
      res = 0;
      do {
        b = encoded.codeUnitAt(i++) - 63;
        res |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (res & 1) != 0 ? ~(res >> 1) : (res >> 1);

      pts.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return pts;
  }


  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(widget.orderId));

    if (raw == null) {
      debugPrint("ℹ️ No previous location found");
      return;
    }

    final data = jsonDecode(raw);

    final lat = data['lat'];
    final lng = data['lng'];
    final reached = data['reached'] ?? false;

    _maidPos = LatLng(lat, lng);
    _reached = reached;

    // ✅ RESTORE STATUS
    _isMaidOnline = !reached;

    debugPrint("📍 RESTORED LAST LOCATION → $_maidPos");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      _updateMap();

      // ✅ ADD THIS
      _updateRouteThrottled();
    });

  }


  // ------------------------------------------------------------
  // CALL
  // ------------------------------------------------------------
  Future<void> _callMaid() async {
    final uri = Uri.parse("tel:${widget.maidPhone}");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------
  @override
  void dispose() {
    if (_socket.onLiveTracking == _handleLiveTracking) {
      _socket.onLiveTracking = null;
    }
    _map?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
            CameraPosition(target: _orderPos, zoom: 14),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (c) {
              _map = c;

              if (_maidPos != null) {
                _updateMap();
                _updateRouteThrottled(); // ✅ SAFETY
              }
            },

          ),


          if (_showArrival)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  "🚴 Arriving in 2 mins",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 22,
                    offset: Offset(0, 10),
                    color: Colors.black26,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order #${widget.orderidNameForShow}",
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.two_wheeler, color: Colors.green),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.maidName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isMaidOnline
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isMaidOnline ? "Online" : "Offline",
                                  style: TextStyle(
                                    color: _isMaidOnline
                                        ? Colors.green
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: _callMaid,
                      ),
                    ],
                  ),


                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text("📏 $_distanceText"),
                      Text("⏱ $_etaText",
                          style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
