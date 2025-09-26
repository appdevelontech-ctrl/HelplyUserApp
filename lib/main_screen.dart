import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/controllers/home_conroller.dart';
import 'package:user_app/controllers/location_controller.dart';
import 'package:user_app/controllers/cart_provider.dart';
import 'package:user_app/views/auth/login_screen.dart';

import 'package:user_app/views/dashboard_screen.dart';
import 'package:user_app/views/my_order_screen.dart';
import 'package:user_app/views/cartpage.dart';

import 'controllers/user_controller.dart';

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
      _ScreenLoader(animationController: _animationController!, child: const UserOrdersPage()),
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

    final userController = Provider.of<UserController>(context);

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          _navigatorKeys[0].currentState?.popUntil((route) => route.isFirst);
          return false;
        }
        // Exit confirmation dialog
        final shouldExit = await _showModernExitDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(65),
          child: AppBar(
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff004e92), Color(0xff000428)],
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
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.blue.shade50,
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
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
              FutureBuilder(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const UserAccountsDrawerHeader(
                      accountName: Text("User"),
                      accountEmail: Text("No phone"),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: NetworkImage("https://i.pravatar.cc/150"),
                      ),
                    );
                  }
                  final prefs = snapshot.data!;
                  final name = prefs.getString('name') ?? "User";
                  final email = prefs.getString('email') ?? "";
                  final phone = prefs.getString('phone') ?? "No phone";

                  return UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff1e3c72), Color(0xff2a5298)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    accountName: Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    accountEmail: Text(
                      email.isNotEmpty ? email : phone,
                      style: const TextStyle(color: Colors.white70),
                    ),

                    currentAccountPicture: const CircleAvatar(
                      backgroundImage: NetworkImage("https://i.pravatar.cc/150"),
                    ),
                  );
                },
              ),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.home, color: Colors.blue),
                      title: Text("Home",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    ListTile(
                      leading: Icon(Icons.build, color: Colors.blue),
                      title: Text("Services",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    ListTile(
                      leading: Icon(Icons.info, color: Colors.blue),
                      title: Text("About Us",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final confirm = await _showModernLogoutDialog(context);
                  if (confirm) {
                    final userController = Provider.of<UserController>(context, listen: false);
                    await userController.logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
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
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff004e92), Color(0xff000428)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
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
                        if (cartProvider.cartItems.isNotEmpty)
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${cartProvider.cartItems.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Cart',
                  )

                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScreenLoader extends StatelessWidget {
  final Widget child;
  final AnimationController animationController;

  const _ScreenLoader({required this.child, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 700)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ModernLoader(animationController: animationController);
        }
        return child;
      },
    );
  }
}
Future<bool> _showModernExitDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xff004e92), Color(0xff000428)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.exit_to_app, size: 60, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              "Exit App",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Do you really want to exit the app?",
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Yes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ) ??
      false;
}

Future<bool> _showModernLogoutDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xff1e3c72), Color(0xff2a5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, size: 60, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              "Logout",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Do you really want to logout?",
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Yes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ) ??
      false;
}


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