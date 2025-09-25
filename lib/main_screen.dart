import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/home_conroller.dart';
import 'controllers/location_controller.dart';
import 'controllers/cart_provider.dart';
import 'views/dashboard_screen.dart';
import 'views/my_order_screen.dart';
import 'views/cartpage.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  AnimationController? _animationController;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initScreens();
  }

  void _initScreens() {
    _screens = [
      _ScreenLoader(animationController: _animationController!, child: const DashboardScreen()),
      _ScreenLoader(animationController: _animationController!, child: const MyOrdersScreen()),
      _ScreenLoader(animationController: _animationController!, child: const CartPage()),
    ];
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Reload screen if current tab tapped again
      setState(() {
        _initScreens();
      });
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (context) => _screens[index],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Provider.of<HomeController>(context);
    final locationController = Provider.of<LocationController>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          _navigatorKeys[0].currentState?.popUntil((route) => route.isFirst);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(65),
          child: AppBar(
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    "https://backend-olxs.onrender.com/uploads/new/image-1755174201972.webp",
                    height: 20,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.green.shade50,
                        value: homeController.selectedLocation,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        onChanged: (val) {
                          if (val != null) homeController.setLocation(val);
                        },
                        items: locationController.locations.map((loc) {
                          return DropdownMenuItem(
                            value: loc,
                            child: Text(
                              loc,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: const [
              CircleAvatar(
                backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
              ),
              SizedBox(width: 12),
            ],
          ),
        ),
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
                  ),
                ),
                accountName: const Text("Rahul Kumar", style: TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: const Text("rahul@example.com"),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: NetworkImage("https://i.pravatar.cc/150"),
                ),
              ),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(leading: Icon(Icons.home), title: Text("Home")),
                    ListTile(leading: Icon(Icons.build), title: Text("Services")),
                    ListTile(leading: Icon(Icons.info), title: Text("About Us")),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout", style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            _buildOffstageNavigator(0),
            _buildOffstageNavigator(1),
            _buildOffstageNavigator(2),
          ],
        ),
        bottomNavigationBar: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.green[700],
              unselectedItemColor: Colors.grey,
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              onTap: _onTabTapped,
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Orders'),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.shopping_cart),
                      if (cartProvider.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: -2,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.red,
                            child: Text(
                              cartProvider.itemCount.toString(),
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'My Cart',
                ),
              ],
            );
          },
        ),

      ),
    );
  }
}

/// Loader wrapper for any screen
class _ScreenLoader extends StatelessWidget {
  final Widget child;
  final AnimationController animationController;

  const _ScreenLoader({required this.child, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 700)), // simulate loading
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ModernLoader(animationController: animationController);
        }
        return child;
      },
    );
  }
}

/// Modern Gradient Loader
class ModernLoader extends StatelessWidget {
  final AnimationController animationController;

  const ModernLoader({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: animationController.value * 2 * 3.14159,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.8),
                    Colors.greenAccent.withOpacity(0.8),
                    Colors.blueAccent.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  startAngle: 0.0,
                  endAngle: 3.14159 * 2,
                  transform: GradientRotation(animationController.value * 2 * 3.14159),
                ),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.refresh,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
