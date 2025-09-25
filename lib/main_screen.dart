  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:shimmer/shimmer.dart';
  import 'package:user_app/views/cartpage.dart';
  import 'package:user_app/views/dashboard_screen.dart';
  import 'package:user_app/views/my_order_screen.dart';
  import 'controllers/home_conroller.dart';
  import 'controllers/cart_provider.dart';

  class MainScreen extends StatefulWidget {
    const MainScreen({super.key});

    @override
    State<MainScreen> createState() => _MainScreenState();
  }

  class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
    int _currentIndex = 0;
    bool _isLoading = false; // Track loading state
    AnimationController? _animationController; // For rotating loader animation

    // Global keys for each tab's Navigator to manage their navigation stacks
    final List<GlobalKey<NavigatorState>> _navigatorKeys = [
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
    ];

    // List of initial screens for each tab
    final List<Widget> _screens = [
      const DashboardScreen(),
      const MyOrdersScreen(),
      const MyCartPage(),
    ];

    // Navigator observers for each tab
    final List<LoadingNavigatorObserver> _observers = [];

    @override
    void initState() {
      super.initState();
      // Initialize animation controller for loader rotation
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(); // Continuous rotation

      // Initialize observers for each tab
      for (int i = 0; i < _screens.length; i++) {
        _observers.add(LoadingNavigatorObserver(
          onPush: () => _setLoading(true),
          onPop: () => _setLoading(true),
        ));
      }
    }

    @override
    void dispose() {
      _animationController?.dispose();
      super.dispose();
    }

    // Handle BottomNavigationBar tap
    void _onTabTapped(int index) async {
      setState(() {
        _isLoading = true; // Show loader
      });
      if (_currentIndex == index) {
        // If the same tab is tapped, pop to the first route (refresh)
        _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      } else {
        // Switch to the selected tab
        setState(() {
          _currentIndex = index;
        });
      }
      // Simulate load time (replace with actual async operations if needed)
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isLoading = false; // Hide loader
      });
    }

    // Set loading state with simulated delay
    void _setLoading(bool value) {
      // Defer setState to after the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          _isLoading = value;
        });
        if (value) {
          // Simulate load time (replace with actual async operations)
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {
            _isLoading = false;
          });
        }
      });
    }

    // Build the Navigator for each tab
    Widget _buildOffstageNavigator(int index) {
      return Offstage(
        offstage: _currentIndex != index,
        child: Navigator(
          key: _navigatorKeys[index],
          observers: [_observers[index]], // Add observer
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => _screens[index],
            );
          },
        ),
      );
    }

    // Handle back navigation
    Future<bool> _onPopInvoked(bool didPop) async {
      if (didPop) return true; // Allow pop if handled by nested Navigator
      if (_currentIndex != 0) {
        // If not on Home tab, switch to Home
        setState(() {
          _isLoading = true; // Show loader
          _currentIndex = 0;
        });
        _navigatorKeys[0].currentState?.popUntil((route) => route.isFirst);
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate load time
        setState(() {
          _isLoading = false; // Hide loader
        });
        return false; // Prevent app exit
      }
      return true; // Allow app exit if on Home tab
    }

    @override
    Widget build(BuildContext context) {
      final cartProvider = Provider.of<CartProvider>(context);
      final controller = Provider.of<HomeController>(context);

      return PopScope(
        canPop: _currentIndex == 0, // Allow pop only on Home tab
        onPopInvoked: _onPopInvoked,
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
                          value: controller.selectedLocation,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          onChanged: (val) async {
                            setState(() {
                              _isLoading = true; // Show loader when changing location
                            });
                            controller.setLocation(val!);
                            await Future.delayed(const Duration(milliseconds: 500)); // Simulate load time
                            setState(() {
                              _isLoading = false; // Hide loader
                            });
                          },
                          items: const [
                            "Select Location",
                            "New Delhi",
                            "Mumbai",
                            "Bangalore"
                          ].map((loc) {
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
              actions: [
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile clicked")),
                    );
                  },
                  child: const CircleAvatar(
                    backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
                  ),
                ),
                const SizedBox(width: 12),
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
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              _buildOffstageNavigator(0), // DashboardScreen
              _buildOffstageNavigator(1), // MyOrdersScreen
              _buildOffstageNavigator(2), // MyCartPage
              // 🔹 Modern Loader Overlay
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: ModernLoader(animationController: _animationController!),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
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
          ),
        ),
      );
    }
  }
  // 🔹 Modern Circular Gradient Loader
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


  // 🔹 Navigator Observer for Loading
  class LoadingNavigatorObserver extends NavigatorObserver {
    final VoidCallback onPush;
    final VoidCallback onPop;

    LoadingNavigatorObserver({required this.onPush, required this.onPop});

    @override
    void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
      // Only trigger for non-initial routes
      if (previousRoute != null) {
        onPush(); // Show loader when pushing a route
      }
    }

    @override
    void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
      onPop(); // Show loader when popping a route
    }
  }