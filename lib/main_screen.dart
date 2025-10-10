import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:user_app/controllers/home_conroller.dart';
import 'package:user_app/controllers/location_controller.dart';
import 'package:user_app/controllers/cart_provider.dart';
import 'package:user_app/controllers/user_controller.dart';
import 'package:user_app/views/PrivacyPolicy_screen.dart';
import 'package:user_app/views/auth/login_screen.dart';
import 'package:user_app/views/cancellation_policy_screen.dart';
import 'package:user_app/views/dashboard_screen.dart';
import 'package:user_app/views/my_order_screen.dart';
import 'package:user_app/views/cartpage.dart';
import 'package:user_app/views/terms_condition_screen.dart';
import 'package:user_app/views/profile_screen.dart';

import 'controllers/order_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  ScrollController? _scrollController; // Make nullable to avoid late initialization issues
  Timer? _scrollTimer; // Timer for auto-scrolling
  bool _scrollForward = true; // Track scrolling direction
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
    // Fetch orders and start auto-scrolling after orders are fetched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false).fetchOrders().then((_) {
        _startAutoScroll();
      });
    });
  }
  void _startAutoScroll() {
    // Cancel any existing timer to avoid duplicates
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_scrollController?.hasClients ?? false) {
        final maxExtent = _scrollController!.position.maxScrollExtent;
        final currentOffset = _scrollController!.offset;

        if (_scrollForward) {
          // Scroll right
          if (currentOffset >= maxExtent) {
            _scrollForward = false; // Reverse direction at the end
          } else {
            _scrollController!.animateTo(
              currentOffset + 50, // Scroll by 50 pixels
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
            );
          }
        } else {
          // Scroll left
          if (currentOffset <= 0) {
            _scrollForward = true; // Reverse direction at the start
          } else {
            _scrollController!.animateTo(
              currentOffset - 50, // Scroll back by 50 pixels
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
            );
          }
        }
      }
    });
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
    _scrollTimer?.cancel(); // Cancel the timer
    _scrollController?.dispose(); // Dispose ScrollController
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
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
            iconTheme: const IconThemeData(color: Colors.white),
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
                    width: 115,
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
                ),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
                  ),
                ),
              ),
            ],
          ),
        ),
        drawer: _buildDrawer(context),
        body:
        Column(
          children: [
            // Horizontally scrollable orders section
            Consumer<OrderController>(
              builder: (context, orderController, _) {
                // Filter orders to show only those with status 2 (accepted) or 5 (started)
                final orders = orderController.orders.where((order) => [2, 5].contains(order.status)).toList();
                if (orders.isEmpty) {
                  return orderController.isOrdersLoading
                      ? Center(child: ModernLoader(animationController: _animationController))
                      : const SizedBox.shrink();
                }
                // Ensure _scrollController is initialized before using it
                if (_scrollController == null) {
                  _scrollController = ScrollController();
                  // Restart auto-scrolling after initialization
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _startAutoScroll();
                  });
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive dimensions based on screen width
                    final screenWidth = MediaQuery.of(context).size.width;
                    final cardWidth = (screenWidth * 0.15).clamp(50.0, 60.0); // Keep width as is
                    final cardHeight = (screenWidth * 0.1).clamp(30.0, 40.0); // Reduced height (from 40–50px)
                    final fontSizeOrderId = (screenWidth * 0.02).clamp(7.0, 8.0); // Smaller Order ID font
                    final fontSizeOtp = (screenWidth * 0.025).clamp(8.0, 10.0); // Smaller OTP font
                    final verticalMargin = (screenWidth * 0.01).clamp(3.0, 4.0); // Reduced margin
                    final rightMargin = (screenWidth * 0.01).clamp(3.0, 4.0); // Reduced card spacing
                    final padding = (screenWidth * 0.01).clamp(3.0, 4.0); // Reduced padding

                    return Container(
                      height: cardHeight,
                      margin: EdgeInsets.symmetric(vertical: verticalMargin, horizontal: 4),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollController, // Attach ScrollController
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Container(
                            width: cardWidth,
                            margin: EdgeInsets.only(right: rightMargin),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xff0052cc), Color(0xff1e3c72)], // Vibrant gradient
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6), // Smaller corners
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 3, // Smaller shadow
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(padding),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'ID: ${order.orderId}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSizeOrderId,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: padding * 0.4), // Reduced spacing
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: padding * 0.5, vertical: padding * 0.2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(3), // Smaller OTP background radius
                                    ),
                                    child: Text(
                                      '${order.otp ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: fontSizeOtp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            // Existing stack of navigators
            Expanded(
              child: Stack(
                children: [
                  _buildOffstageNavigator(0),
                  _buildOffstageNavigator(1),
                  _buildOffstageNavigator(2),
                ],
              ),
            ),
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
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
              ],
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
            Consumer<UserController>(
              builder: (context, userController, _) {
                final user = userController.user;
                final username = user?.username ?? 'User';
                final email = user?.email ?? '';
                final phone = user?.phone ?? 'No phone';
                return UserAccountsDrawerHeader(
                  accountName: Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(
                    email.isNotEmpty ? email : phone,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(
                      "https://i.pravatar.cc/150?img=${username.hashCode % 70}",
                    ),
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff306694), Color(0xff9e5ccb)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
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
                      Navigator.pop(context);
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.person,
                    title: "Profile Page",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.privacy_tip,
                    title: "Privacy Policy",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()));
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.rule,
                    title: "Terms and Conditions",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TermsConditionsScreen()));
                    },
                    iconColor: Colors.black,
                    textColor: Colors.black,
                  ),
                  DrawerTile(
                    icon: Icons.money_off,
                    title: "Cancellation Policy",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CancellationPolicyScreen()));
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
                      Navigator.pop(context);
                      final confirmed = await _showModernDeleteAccountDialog(context);
                      if (confirmed) {
                        final userController = Provider.of<UserController>(context, listen: false);
                        try {
                          await userController.deleteAccount(context);
                          await userController.logout();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting account: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, thickness: 1),
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

  Future<bool> _showModernExitDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [Color(0xff004e92), Color(0xff000428)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.exit_to_app, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              const Text("Exit App", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text("Do you really want to exit the app?",
                  style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [Color(0xff1e3c72), Color(0xff2a5298)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              const Text("Logout", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text("Do you really want to logout?",
                  style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  Future<bool> _showModernDeleteAccountDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [Color(0xffa94ee7), Color(0xff2a5298)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_forever, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              const Text("Delete Account",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to delete your account? This action cannot be undone.",
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
}

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
      leading: Icon(icon, color: iconColor ?? Colors.black, size: 22),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.black, fontWeight: FontWeight.w600, fontSize: 15)),
      onTap: onTap,
      horizontalTitleGap: 0,
    );
  }
}