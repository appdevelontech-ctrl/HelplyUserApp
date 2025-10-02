import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';

class LiveTrackingPage extends StatefulWidget {
  final String orderId;

  const LiveTrackingPage({super.key, required this.orderId});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  double? _distance;
  String? _estimatedTime;
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrderDetails();
      _calculateDistanceAndETA();
      _startRefreshTimer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orderController = Provider.of<OrderController>(context);
    orderController.addListener(_updateMapAndCalculations);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _refreshTimer?.cancel();
    final orderController =
        Provider.of<OrderController>(context, listen: false);
    orderController.removeListener(_updateMapAndCalculations);
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (mounted) {
        _fetchOrderDetails();
        _calculateDistanceAndETA();
        _updateMapAndCalculations();
      }
    });
  }

  Future<void> _fetchOrderDetails() async {
    final orderController = context.read<OrderController>();
    try {
      await orderController.fetchOrderDetails(widget.orderId);
      print('📦 Fetched order details for orderId: ${widget.orderId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch order details: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _calculateDistanceAndETA() async {
    final orderController = context.read<OrderController>();
    final order = orderController.orderDetails;
    if (order == null ||
        order.maidLat == null ||
        order.maidLng == null ||
        order.userLat == null ||
        order.userLng == null) {
      return;
    }

    try {
      final distanceInMeters = Geolocator.distanceBetween(
        order.userLat!,
        order.userLng!,
        order.maidLat!,
        order.maidLng!,
      );
      if (mounted) {
        setState(() {
          _distance = distanceInMeters / 1000; // Convert to kilometers
        });
      }

      const averageSpeedKmh = 30.0;
      final timeInHours = _distance! / averageSpeedKmh;
      final timeInMinutes = (timeInHours * 60).round();
      if (mounted) {
        setState(() {
          _estimatedTime = '$timeInMinutes minutes';
        });
      }
    } catch (e) {
      print('❌ Error calculating distance/ETA: $e');
    }
  }

  void _updateMapAndCalculations() {
    final orderController =
        Provider.of<OrderController>(context, listen: false);
    final order = orderController.orderDetails;
    if (order == null ||
        order.maidLat == null ||
        order.maidLng == null ||
        order.userLat == null ||
        order.userLng == null) {
      return;
    }

    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('user'),
        position: LatLng(order.userLat!, order.userLng!),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
      _markers.add(Marker(
        markerId: const MarkerId('maid'),
        position: LatLng(order.maidLat!, order.maidLng!),
        infoWindow: InfoWindow(title: order.maidName ?? 'Maid'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
      _polylines.clear();
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(order.userLat!, order.userLng!),
          LatLng(order.maidLat!, order.maidLng!),
        ],
        color: Colors.blue,
        width: 5,
      ));
    });
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(order.userLat!, order.userLng!), 14),
    );
    _calculateDistanceAndETA();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Tracking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          final order = controller.orderDetails;
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (order == null || order.id != widget.orderId) {
            return const Center(child: Text('Order details not found'));
          }

          if (_distance == null || _estimatedTime == null) {
            _calculateDistanceAndETA();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
// Order Details
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${order.orderId}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Item: ${order.items.isNotEmpty ? order.items[0].title : 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          'Status: ${_statusText(order.status)}',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

// Maid Details
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Maid Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Name: ${order.maidName ?? 'Not assigned'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Phone: ${order.maidPhone ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Email: ${order.maidEmail ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

// Distance and ETA
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tracking Information',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Distance: ${_distance != null ? _distance!.toStringAsFixed(2) + ' km' : 'Calculating...'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Estimated Time: ${_estimatedTime ?? 'Calculating...'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

// Map View Section
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Map View',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 300,
                          child: GoogleMap(
                            onMapCreated: (controller) {
                              _mapController = controller;
                              _updateMapAndCalculations();
                            },
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(
                                  20.5937, 78.9629), // Default to India center
                              zoom: 5,
                            ),
                            markers: _markers,
                            polylines: _polylines,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusText(int status) {
    switch (status) {
      case 0:
        return "Pending";
      case 1:
        return "Confirmed";
      case 2:
        return "Processing";
      case 5:
        return "Cancelled";
      case 7:
        return "Delivered";
      default:
        return "Unknown";
    }
  }
}
