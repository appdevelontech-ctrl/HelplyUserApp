import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/controllers/home_conroller.dart';
import 'package:user_app/controllers/location_controller.dart';
import 'package:user_app/controllers/cart_provider.dart';
import 'package:user_app/controllers/user_controller.dart';
import 'package:user_app/views/auth/login_screen.dart';
import 'package:user_app/views/dashboard_screen.dart';
import 'package:user_app/views/my_order_screen.dart';
import 'package:user_app/views/cartpage.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

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
      _ScreenLoader(animationController: _animationController, child: const DashboardScreen()),
      _ScreenLoader(animationController: _animationController, child: const UserOrdersPage()),
      _ScreenLoader(animationController: _animationController, child: const CartPage()),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;

      // Reload screen for the tapped index
      switch (index) {
        case 0:
          _screens[0] = _ScreenLoader(
            animationController: _animationController,
            child: const DashboardScreen(),
          );
          break;
        case 1:
          _screens[1] = _ScreenLoader(
            animationController: _animationController,
            child: const UserOrdersPage(),
          );
          break;
        case 2:
          _screens[2] = _ScreenLoader(
            animationController: _animationController,
            child: const CartPage(),
          );
          break;
      }
    });
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

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          _navigatorKeys[0].currentState?.popUntil((route) => route.isFirst);
          return false;
        }
        return await _showModernExitDialog(context);
      },
      child: Scaffold(
        appBar: PreferredSize(

          preferredSize: const Size.fromHeight(65),
          child: AppBar(
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white), // ← ye add karo
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
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Consumer<HomeController>(
                      builder: (context, homeController, _) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: Colors.white,
                            value: homeController.selectedLocation,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                            onChanged: (val) {
                              if (val != null) homeController.setLocation(val);
                            },
                            selectedItemBuilder: (_) {
                              return Provider.of<LocationController>(context, listen: false)
                                  .locations
                                  .map((loc) => Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      loc,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width * 0.035,
                                        fontWeight: FontWeight.w600,
                                        color: loc == "Select Location"
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ))
                                  .toList();
                            },
                            items: Provider.of<LocationController>(context, listen: false)
                                .locations
                                .map((loc) => DropdownMenuItem(
                              value: loc,
                              child: Text(
                                loc,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                                .toList(),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
            actions: const [
              CircleAvatar(backgroundImage: NetworkImage("https://i.pravatar.cc/300")),
              SizedBox(width: 12),
            ],
          ),
        ),
        drawer: _buildDrawer(context),
        body: Stack(
          children: [
            _buildOffstageNavigator(0),
            _buildOffstageNavigator(1),
            _buildOffstageNavigator(2),
          ],
        ),
        bottomNavigationBar: Consumer<CartProvider>(
          builder: (_, cartProvider, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: BottomNavigationBar(
                backgroundColor: Colors.white.withOpacity(0.9),
                elevation: 0,
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.blueAccent,
                unselectedItemColor: Colors.grey.shade500,
                showUnselectedLabels: true,
                onTap: _onTabTapped,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                items: [
                  BottomNavigationBarItem(
                    icon: AnimatedScale(
                      scale: _currentIndex == 0 ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.home, color: _currentIndex == 0 ? Colors.blueAccent : Colors.grey),
                    ),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: AnimatedScale(
                      scale: _currentIndex == 1 ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.list_alt, color: _currentIndex == 1 ? Colors.blueAccent : Colors.grey),
                    ),
                    label: "My Orders",
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        AnimatedScale(
                          scale: _currentIndex == 2 ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(Icons.shopping_cart, color: _currentIndex == 2 ? Colors.blueAccent : Colors.grey),
                        ),
                        if (cartProvider.cartItems.isNotEmpty)
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                '${cartProvider.cartItems.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: "Cart",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe7e2e2), Color(0xffffffff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Drawer Header with User Info
            FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  // Simplified loading state for header
                  return Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xffa94ee7), Color(0xff2a5298)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }
                final prefs = snapshot.data!;
                final name = prefs.getString('name') ?? "User";
                final email = prefs.getString('email') ?? "";
                final phone = prefs.getString('phone') ?? "No phone";
                return UserAccountsDrawerHeader(
                  accountName: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(
                    email.isNotEmpty ? email : phone,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(
                      "https://i.pravatar.cc/150?img=${name.hashCode % 70}",
                    ),
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xffa94ee7), Color(0xff2a5298)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerTile(
                    icon: Icons.home,
                    title: "Home",
                    onTap: () {
                      setState(() => _currentIndex = 0);
                      _navigatorKeys[0].currentState?.popUntil((route) => route.isFirst);
                      Navigator.pop(context); // Close drawer
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.build,
                    title: "Services",
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Add navigation logic for Services if needed
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.person,
                    title: "Profile Page",
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Add navigation logic for Profile if needed
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.privacy_tip,
                    title: "Privacy Policy",
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Add navigation logic for Privacy Policy if needed
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.rule,
                    title: "Terms and Conditions",
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Add navigation logic for Terms and Conditions if needed
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.money_off,
                    title: "Refund Policy",
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // Add navigation logic for Refund Policy if needed
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.delete_forever,
                    title: "Delete Account",
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () async {
                      Navigator.pop(context); // Close drawer
                      // Add delete account logic if needed
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white54, thickness: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                if (await _showModernLogoutDialog(context)) {
                  final userController = Provider.of<UserController>(context, listen: false);
                  await userController.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

}

// Screen Loader
class _ScreenLoader extends StatelessWidget {
  final Widget child;
  final AnimationController animationController;
  const _ScreenLoader({required this.child, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 700)),
      builder: (_, snapshot) => snapshot.connectionState != ConnectionState.done
          ? ModernLoader(animationController: animationController)
          : child,
    );
  }
}

// Modern Loader
class ModernLoader extends StatelessWidget {
  final AnimationController animationController;
  const ModernLoader({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: animationController,
        builder: (_, __) => Transform.rotate(
          angle: animationController.value * 2 * 3.14159,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [Colors.blueAccent.withOpacity(0.8), Colors.greenAccent.withOpacity(0.8), Colors.blueAccent.withOpacity(0.8)],
                stops: const [0.0, 0.5, 1.0],
                transform: GradientRotation(animationController.value * 2 * 3.14159),
              ),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.refresh, color: Colors.blueAccent, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Drawer Tile
class DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const DrawerTile({super.key, required this.icon, required this.title, required this.onTap, this.iconColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white, size: 22),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
      onTap: onTap,
      horizontalTitleGap: 0,
    );
  }
}

// Exit Dialog
Future<bool> _showModernExitDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xff004e92), Color(0xff000428)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.exit_to_app, size: 60, color: Colors.white),
            const SizedBox(height: 16),
            const Text("Exit App", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            const Text("Do you really want to exit the app?", style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

// Logout Dialog
Future<bool> _showModernLogoutDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xff1e3c72), Color(0xff2a5298)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, size: 60, color: Colors.white),
            const SizedBox(height: 16),
            const Text("Logout", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            const Text("Do you really want to logout?", style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
