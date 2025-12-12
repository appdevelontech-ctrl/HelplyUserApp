import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../controllers/home_conroller.dart';
import '../controllers/location_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/cart_provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/socket_controller.dart';

import '../views/dashboard_screen.dart';
import '../views/cartpage.dart';
import '../views/my_order_screen.dart';
import '../views/profile_screen.dart';
import '../views/PrivacyPolicy_screen.dart';
import '../views/cancellation_policy_screen.dart';
import '../views/terms_condition_screen.dart';
import '../views/auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  Timer? _scrollTimer;
  ScrollController? _scrollController;
  bool _scrollForward = true;

  late AnimationController _loader;

  @override
  void initState() {
    super.initState();

    _loader = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false)
          .fetchOrders()
          .then((_) => _startAutoScroll());
    });
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollController?.dispose();
    super.dispose();
  }

  // -----------------------------------------------
  // AUTO SCROLL ORDER STATUS (ZEPT0 STYLE)
  // -----------------------------------------------
  void _startAutoScroll() {
    _scrollTimer?.cancel();

    _scrollTimer =
        Timer.periodic(const Duration(milliseconds: 260), (timer) {
          if (_scrollController?.hasClients ?? false) {
            final max = _scrollController!.position.maxScrollExtent;
            final current = _scrollController!.offset;

            if (_scrollForward && current < max) {
              _scrollController!.animateTo(
                current + 45,
                duration: const Duration(milliseconds: 240),
                curve: Curves.linear,
              );
            } else if (!_scrollForward && current > 0) {
              _scrollController!.animateTo(
                current - 45,
                duration: const Duration(milliseconds: 240),
                curve: Curves.linear,
              );
            } else {
              _scrollForward = !_scrollForward;
            }
          }
        });
  }

  // ----------------------------------
  // SCREENS
  // ----------------------------------
  final List<Widget> _screens = const [
    DashboardScreen(),
    UserOrdersPage(),
    CartPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,

        drawer: _buildDrawer(),
        appBar: _buildPremiumAppBar(),

        body: Column(
          children: [
            _buildAutoScrollOrders(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: _buildFloatingBottomBar(),
      ),
    );
  }

  // --------------------------------------------------------------------
  // PREMIUM TOP APPBAR (MODERN GRADIENT LIKE ZEPT0 + URBAN COMPANY)
  // --------------------------------------------------------------------
  PreferredSizeWidget _buildPremiumAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: AppBar(
        elevation: 4,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // ❗ IMPORTANT

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
            // 🔥 WHITE MENU ICON
            // 🔥 ANIMATED MENU ICON (Smooth Press Animation)
            Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: AnimatedScale(
                    scale: 1,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                );
              },
            ),


            const SizedBox(width: 6),

            // 🔥 LOGO
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                "https://backend-olxs.onrender.com/uploads/new/image-1755174201972.webp",
                height: 22,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 12),

            // 🔥 LOCATION DROPDOWN
            Expanded(child: _locationSelector()),
          ],
        ),

        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 350),
                    pageBuilder: (_, __, ___) => ProfileScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      final offset = Tween(begin: Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                      return SlideTransition(position: offset, child: child);
                    },
                  ));
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(
                backgroundImage: AssetImage("assets/images/profile.png"),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // -----------------------------
  // LOCATION DROPDOWN (PREMIUM)
  // -----------------------------
  // -----------------------------
// 🔥 RESPONSIVE PREMIUM DROPDOWN
// -----------------------------
  Widget _locationSelector() {
    final width = MediaQuery.of(context).size.width;

    // Dynamic sizes for all devices
    double fontSize = width * 0.032;   // 3.2% of width
    double iconSize = width * 0.05;    // 5% of width
    double horizontalPad = width * 0.02;

    return Consumer<HomeController>(
      builder: (context, home, _) {
        final locations =
            Provider.of<LocationController>(context, listen: false).locations;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: width * 0.01,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: home.selectedLocation,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: iconSize,
              ),

              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),

              /// when user selects new location
              onChanged: (value) => home.setLocation(value!),

              /// CLOSED DROPDOWN TEXT (WHITE)
              selectedItemBuilder: (_) {
                return locations.map((loc) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: iconSize * 0.8,
                        ),
                        SizedBox(width: width * 0.015),
                        Flexible(
                          child: Text(
                            loc,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },

              /// OPEN DROPDOWN TEXT (BLACK)
              items: locations.map((loc) {
                return DropdownMenuItem(
                  value: loc,
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.blueAccent,
                        size: iconSize * 0.8,
                      ),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: Text(
                          loc,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }


  // ---------------------------------------
  // AUTO SCROLL ORDERS (SLIM MODERN BAR)
  // ---------------------------------------
  bool _userScrolling = false;
  Timer? _resumeTimer;

  Widget _buildAutoScrollOrders() {
    return Consumer<OrderController>(
      builder: (_, orderCtrl, __) {
        final running = orderCtrl.orders
            .where((o) => [2, 5].contains(o.status))
            .toList();

        if (running.isEmpty) return const SizedBox(height: 0);

        if (_scrollController == null) {
          _scrollController = ScrollController();

          // 👇 Listen for manual scroll
          _scrollController!.addListener(() {
            final pos = _scrollController!.position;

            if (pos.isScrollingNotifier.value && !_userScrolling) {
              // USER START SCROLLING → stop auto-scroll
              _userScrolling = true;
              _scrollTimer?.cancel();
            }

            if (!pos.isScrollingNotifier.value && _userScrolling) {
              // USER STOPPED SCROLLING → restart auto-scroll after 2 sec
              _userScrolling = false;
              _resumeTimer?.cancel();
              _resumeTimer = Timer(const Duration(seconds: 2), () {
                _startAutoScroll();
              });
            }
          });

          WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
        }

        return Container(
          height: 42,
          margin: const EdgeInsets.only(bottom: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            itemCount: running.length,
            itemBuilder: (_, i) {
              final o = running[i];

              return Container(
                width: 70,
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xff0052cc), Color(0xff1e3c72)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.2),
                      blurRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "ID:${o.orderId}",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      "${o.otp ?? 'N/A'}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


  // ---------------------------------------
  // FLOATING BOTTOM NAVBAR (ZEPT0 STYLE)
  // ---------------------------------------
  Widget _buildFloatingBottomBar() {
    return Consumer<CartProvider>(
      builder: (_, cart, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),

            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: "Home",
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded),
                label: "Orders",
              ),

              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_rounded),
                    if (cart.cartItems.isNotEmpty)
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            "${cart.cartItems.length}",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
                label: "Cart",
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------
  // PREMIUM DRAWER (URBAN COMPANY STYLE)
  // ---------------------------------------
  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          Consumer<UserController>(
            builder: (_, u, __) {
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff306694), Color(0xff9e5ccb)],
                  ),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: AssetImage("assets/images/profile.png"),
                ),
                accountName: Text(
                  u.user?.username ?? "User",
                  style: const TextStyle(color: Colors.white),
                ),
                accountEmail: Text(
                  u.user?.email ?? u.user?.phone ?? "",
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),

          _drawerItem(Icons.home, "Home", () {
            setState(() => _currentIndex = 0);
            Navigator.pop(context);
          }),

          _drawerItem(Icons.person, "Profile", () {
            Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 350),
                  pageBuilder: (_, __, ___) => ProfileScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    final offset = Tween(begin: Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                    return SlideTransition(position: offset, child: child);
                  },
                ));          }),

          _drawerItem(Icons.rule, "Terms & Conditions", () {
            Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 350),
                  pageBuilder: (_, __, ___) => TermsConditionsScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    final offset = Tween(begin: Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                    return SlideTransition(position: offset, child: child);
                  },
                ));          }),

          _drawerItem(Icons.privacy_tip, "Privacy Policy", () {
            Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 350),
                  pageBuilder: (_, __, ___) => PrivacyPolicyScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    final offset = Tween(begin: Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                    return SlideTransition(position: offset, child: child);
                  },
                ));          }),

          _drawerItem(Icons.cancel, "Cancellation Policy", () {
            Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 350),
                  pageBuilder: (_, __, ___) => CancellationPolicyScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    final offset = Tween(begin: Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                    return SlideTransition(position: offset, child: child);
                  },
                ));          }),

          const Divider(),

          _drawerItem(Icons.delete_forever, "Delete Account", () {
            Navigator.pop(context);
            _confirmDeleteAccount(context);
          }, color: Colors.red),

          _drawerItem(Icons.logout, "Logout", () {
            _confirmLogout(context);
          }, color: Colors.red),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.black87}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  // ---------------------------------------
  // LOGOUT CONFIRMATION
  // ---------------------------------------
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await Provider.of<SocketController>(context, listen: false)
                  .clearUserDataOnLogout();

              Provider.of<OrderController>(context, listen: false)
                  .clearOrders();

              await Provider.of<UserController>(context, listen: false)
                  .logout();

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------
  // DELETE ACCOUNT CONFIRMATION
  // ---------------------------------------
  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to permanently delete your account?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<UserController>(context, listen: false)
                  .deleteAccount(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------
  // EXIT CONFIRMATION
  // ---------------------------------------
  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Do you really want to exit?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes")),
        ],
      ),
    ) ??
        false;
  }
}
