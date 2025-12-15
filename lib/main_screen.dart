import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../controllers/home_conroller.dart';
import '../controllers/location_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/cart_provider.dart';
import '../controllers/user_controller.dart';

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
  Timer? _resumeTimer;
  ScrollController? _scrollController;
  bool _scrollForward = true;
  bool _userScrolling = false;

  late AnimationController _loader;

  final List<Widget> _screens = const [
    DashboardScreen(),
    UserOrdersPage(),
    CartPage(),
  ];

  @override
  void initState() {
    super.initState();

    _loader = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false)
          .fetchOrders()
          .then((_) => _startAutoScroll());
    });
  }

  @override
  void dispose() {
    _loader.dispose();
    _resumeTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollController?.dispose();
    super.dispose();
  }

  // ------------------------------------------------
  // AUTO SCROLL
  // ------------------------------------------------
  void _startAutoScroll() {
    _scrollTimer?.cancel();

    _scrollTimer = Timer.periodic(
      const Duration(milliseconds: 260),
          (_) {
        if (!(_scrollController?.hasClients ?? false)) return;

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
      },
    );
  }

  // ------------------------------------------------
  // BUILD
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

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
        drawer: _buildDrawer(w),
        appBar: _buildAppBar(w),
        body: Column(
          children: [
            _buildAutoScrollOrders(w),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(w),
      ),
    );
  }

  // ------------------------------------------------
  // APP BAR
  // ------------------------------------------------
  PreferredSizeWidget _buildAppBar(double w) {
    return PreferredSize(
      preferredSize: Size.fromHeight(w * 0.18),
      child: AppBar(
        elevation: 4,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff004e92), Color(0xff000428)],
            ),
          ),
        ),
        title: Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  padding: EdgeInsets.all(w * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(w * 0.025),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: w * 0.06,
                  ),
                ),
              ),
            ),
            SizedBox(width: w * 0.02),
            Image.network(
              "https://backend-olxs.onrender.com/uploads/new/image-1755174201972.webp",
              width: w * 0.3,
              height: w * 0.06,
              fit: BoxFit.contain,
            ),
            SizedBox(width: w * 0.02),
            Expanded(child: _locationSelector(w)),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: w * 0.03),
            child: CircleAvatar(
              radius: w * 0.045,
              backgroundImage: const AssetImage("assets/images/profile.png"),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------
  // LOCATION
  // ------------------------------------------------
  Widget _locationSelector(double w) {
    return Consumer<HomeController>(
      builder: (_, home, __) {
        final locations =
            Provider.of<LocationController>(context, listen: false).locations;

        return SizedBox(
          height: w * 0.092, // 🔥 slightly more height
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.02,
              vertical: w * 0.006,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: home.selectedLocation,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: w * 0.047,
                ),
                dropdownColor: Colors.white,
                onChanged: (v) => home.setLocation(v!),

                selectedItemBuilder: (_) => locations.map((loc) {
                  return Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: w * 0.039,
                      ),
                      SizedBox(width: w * 0.012),
                      Expanded(
                        child: Text(
                          loc,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.034,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),

                items: locations.map((loc) {
                  return DropdownMenuItem(
                    value: loc,
                    child: Text(
                      loc,
                      style: TextStyle(
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }





  // ------------------------------------------------
  // AUTO SCROLL ORDERS
  // ------------------------------------------------
  Widget _buildAutoScrollOrders(double w) {
    return Consumer<OrderController>(
      builder: (_, ctrl, __) {
        final running =
        ctrl.orders.where((o) => [2, 5].contains(o.status)).toList();

        if (running.isEmpty) return const SizedBox.shrink();

        _scrollController ??= ScrollController()
          ..addListener(() {
            if (_scrollController!.position.isScrollingNotifier.value &&
                !_userScrolling) {
              _userScrolling = true;
              _scrollTimer?.cancel();
            }
            if (!_scrollController!.position.isScrollingNotifier.value &&
                _userScrolling) {
              _userScrolling = false;
              _resumeTimer = Timer(
                const Duration(seconds: 2),
                _startAutoScroll,
              );
            }
          });

        return SizedBox(
          height: w * 0.12,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: running.length,
            itemBuilder: (_, i) {
              final o = running[i];
              return Container(
                width: w * 0.18,
                margin: EdgeInsets.all(w * 0.015),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff0052cc), Color(0xff1e3c72)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("ID:${o.orderId}",
                        style: TextStyle(
                            color: Colors.white, fontSize: w * 0.028)),
                    Text("${o.otp ?? 'N/A'}",
                        style: TextStyle(
                            color: Colors.white, fontSize: w * 0.032)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ------------------------------------------------
  // BOTTOM NAV
  // ------------------------------------------------
  Widget _buildBottomNav(double w) {
    return Consumer<CartProvider>(
      builder: (_, cart, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(w * 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 15,
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            selectedFontSize: w * 0.035,
            unselectedFontSize: w * 0.03,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: w * 0.065),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded, size: w * 0.065),
                label: "Orders",
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.shopping_cart, size: w * 0.065),
                    if (cart.cartItems.isNotEmpty)
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: w * 0.022,
                          backgroundColor: Colors.red,
                          child: Text(
                            "${cart.cartItems.length}",
                            style: TextStyle(
                              fontSize: w * 0.022,
                              color: Colors.white,
                            ),
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

  // ------------------------------------------------
  // DRAWER
  // ------------------------------------------------
  Drawer _buildDrawer(double w) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            /// 🔥 HEADER
            Consumer<UserController>(
              builder: (_, u, __) => Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.05,
                  vertical: w * 0.06,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff306694), Color(0xff9e5ccb)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: w * 0.085,
                      backgroundImage:
                      const AssetImage("assets/images/profile.png"),
                    ),
                    SizedBox(width: w * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.user?.username ?? "User",
                            style: TextStyle(
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: w * 0.01),
                          Text(
                            u.user?.email ?? "",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: w * 0.034,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 🔥 MENU LIST
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(top: w * 0.02),
                children: [
                  _drawerTile(
                    w,
                    Icons.home_rounded,
                    "Home",
                        () {
                      setState(() => _currentIndex = 0);
                      Navigator.pop(context);
                    },
                  ),

                  _drawerTile(
                    w,
                    Icons.person_rounded,
                    "Profile",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen()),
                      );
                    },
                  ),

                  Divider(thickness: 1, indent: w * 0.05, endIndent: w * 0.05),

                  _drawerTile(
                    w,
                    Icons.rule_rounded,
                    "Terms & Conditions",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TermsConditionsScreen()),
                      );
                    },
                  ),

                  _drawerTile(
                    w,
                    Icons.privacy_tip_rounded,
                    "Privacy Policy",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PrivacyPolicyScreen()),
                      );
                    },
                  ),

                  _drawerTile(
                    w,
                    Icons.cancel_rounded,
                    "Cancellation Policy",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CancellationPolicyScreen()),
                      );
                    },
                  ),

                  SizedBox(height: w * 0.06),

                  /// 🔥 DANGER ZONE
                  Divider(thickness: 1, indent: w * 0.05, endIndent: w * 0.05),

                  _drawerTile(
                    w,
                    Icons.logout_rounded,
                    "Logout",
                        () => _confirmLogout(context),
                    color: Colors.redAccent,
                  ),

                  _drawerTile(
                    w,
                    Icons.delete_forever_rounded,
                    "Delete Account",
                        () => _confirmDeleteAccount(context),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
      double w,
      IconData icon,
      String title,
      VoidCallback onTap, {
        Color color = Colors.black87,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.05,
          vertical: w * 0.035,
        ),
        child: Row(
          children: [
            Icon(icon, size: w * 0.06, color: color),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: w * 0.035,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }


  void _confirmDeleteAccount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: w * 0.07),
            SizedBox(width: w * 0.02),
            const Text("Delete Account"),
          ],
        ),
        content: const Text(
          "This action is permanent.\nYour account and all data will be deleted.\n\nDo you want to continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);

              // 🔥 Call API / Controller method
              await Provider.of<UserController>(
                context,
                listen: false,
              ).deleteAccount(context);

              // 🔁 Redirect to Login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


  // ------------------------------------------------
  // EXIT
  // ------------------------------------------------
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

  // ------------------------------------------------
  // LOGOUT
  // ------------------------------------------------
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<UserController>(context, listen: false)
                  .logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
