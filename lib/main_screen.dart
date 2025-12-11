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
import 'controllers/socket_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _loader;

  ScrollController? _scrollController;
  Timer? _scrollTimer;
  bool _scrollForward = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false).fetchOrders().then((_) {
        _startAutoScroll();
      });
    });
  }

  /// 🔄 Auto Scroll Orders
  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 280), (timer) {
      if (_scrollController?.hasClients ?? false) {
        final max = _scrollController!.position.maxScrollExtent;
        final off = _scrollController!.offset;

        if (_scrollForward && off < max) {
          _scrollController!.animateTo(off + 45,
              duration: const Duration(milliseconds: 260), curve: Curves.linear);
        } else if (!_scrollForward && off > 0) {
          _scrollController!.animateTo(off - 45,
              duration: const Duration(milliseconds: 260), curve: Curves.linear);
        } else {
          _scrollForward = !_scrollForward;
        }
      }
    });
  }

  @override
  void dispose() {
    _loader.dispose();
    _scrollTimer?.cancel();
    _scrollController?.dispose();
    super.dispose();
  }

  /// 📌 Bottom Screens (Only Three)
  final List<Widget> _pages = const [
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
        return _exitAppDialog(context);
      },
      child: Scaffold(
        appBar: _customAppBar(context),
        drawer: _customDrawer(context),

        body: Column(
          children: [
            _ordersAutoScrollBar(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
          ],
        ),

        bottomNavigationBar: _bottomNavigationBar(),
      ),
    );
  }

  /// 🎨 Custom AppBar
  PreferredSizeWidget _customAppBar(BuildContext context) {
    return PreferredSize(
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
                height: 20, width: 115, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _locationDropdown()),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true)
                  .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(backgroundImage: AssetImage("assets/images/profile.png")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationDropdown() {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,  // 👈 responsive padding
        vertical: width * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Consumer<HomeController>(
        builder: (context, home, _) {
          return DropdownButtonHideUnderline(
            child:
            DropdownButton<String>(
              isExpanded: true,
              value: home.selectedLocation,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: width * 0.05,
              ),

              dropdownColor: Colors.white,

              onChanged: (val) => home.setLocation(val!),

              /// 👉 Closed dropdown text styling (White)
              selectedItemBuilder: (context) {
                return Provider.of<LocationController>(context, listen: false)
                    .locations
                    .map(
                      (loc) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      loc,
                      style: TextStyle(
                        fontSize: width * 0.035,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                )
                    .toList();
              },

              /// 👉 Open dropdown menu items styling (BLACK)
              items: Provider.of<LocationController>(context, listen: false)
                  .locations
                  .map(
                    (loc) => DropdownMenuItem(
                  value: loc,
                  child: Text(
                    loc,
                    style: TextStyle(
                      fontSize: width * 0.035,
                      color: Colors.black87, // 👈 now visible in white dropdown!
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  .toList(),
            )

          );
        },
      ),
    );
  }



  /// 🔁 Orders Auto Scroll Bar
  Widget _ordersAutoScrollBar() {
    return Consumer<OrderController>(
      builder: (_, orderCtrl, __) {
        final data = orderCtrl.orders.where((o) => [2, 5].contains(o.status)).toList();
        if (data.isEmpty) return const SizedBox(height: 0);

        if (_scrollController == null) {
          _scrollController = ScrollController();
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
        }

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            itemCount: data.length,
            itemBuilder: (_, i) {
              final o = data[i];
              return Container(
                width: 55,
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xff0052cc), Color(0xff1e3c72)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("ID:${o.orderId}", style: const TextStyle(color: Colors.white, fontSize: 8)),
                    Text("${o.otp ?? 'N/A'}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 🧭 Bottom Navigation Bar
  Widget _bottomNavigationBar() {
    return Consumer<CartProvider>(
      builder: (_, cart, __) {
        return BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart),
                  if (cart.cartItems.isNotEmpty)
                    Positioned(
                      right: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.redAccent,
                        child: Text("${cart.cartItems.length}",
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
              label: "Cart",
            ),
          ],
        );
      },
    );
  }
  /// 🍔 Drawer Section
  Drawer _customDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Consumer<UserController>(
            builder: (_, u, __) {
              return UserAccountsDrawerHeader(
                accountName: Text(u.user?.username ?? "User", style: const TextStyle(color: Colors.white)),
                accountEmail: Text(u.user?.email ?? u.user?.phone ?? "", style: const TextStyle(color: Colors.white)),
                currentAccountPicture: const CircleAvatar(backgroundImage: AssetImage("assets/images/profile.png")),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xff306694), Color(0xff9e5ccb)]),
                ),
              );
            },
          ),

          ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              }),

          ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile Page"),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }),

          ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text("Privacy Policy"),
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()));
              }),

          ListTile(
              leading: const Icon(Icons.rule),
              title: const Text("Terms & Conditions"),
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => TermsConditionsScreen()));
              }),

          ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text("Cancellation Policy"),
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => CancellationPolicyScreen()));
              }),

          // ❌ Delete Account
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text("Delete Account", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteAccount(context);
            },
          ),

          const Divider(),

          // 🚪 Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              _confirmLogout(context);
            },
          ),
        ],
      ),
    );
  }

  /// ❓ Logout Confirmation Dialog
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // 🔥 Clear Local Data First
              await Provider.of<SocketController>(context, listen: false).clearUserDataOnLogout();
              Provider.of<OrderController>(context, listen: false).clearOrders();

              // 🔥 Then Logout User Model
              await Provider.of<UserController>(context, listen: false).logout();

              Navigator.of(context, rootNavigator: true)
                  .pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),

        ],
      ),
    );
  }

  /// 🗑 Delete Account Confirmation Dialog
  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to permanently delete your account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Provider.of<UserController>(context, listen: false).deleteAccount(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }


  /// 🚪 Exit App Dialog
  Future<bool> _exitAppDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Do you really want to exit?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    ) ?? false;
  }
}
