import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_app/views/cartpage.dart';
import 'package:user_app/views/dashboard_screen.dart';
import 'package:user_app/views/my_order_screen.dart';
import 'package:user_app/views/profile.dart';
import 'controllers/home_conroller.dart';
import 'controllers/cart_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MyOrdersScreen(),
    const MyCartPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final controller = Provider.of<HomeController>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[100],
        title: Row(
          children: [
            Image.network(
              "https://backend-olxs.onrender.com/uploads/new/image-1755174201972.webp",
              height: 32,
              width: 80,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedLocation,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        size: 20, color: Colors.black),
                    onChanged: _currentIndex == 0
                        ? (val) => controller.setLocation(val!)
                        : null,
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
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
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
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, color: Colors.black54),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      "https://backend-olxs.onrender.com/uploads/new/image-1758194895880.webp"),
                  fit: BoxFit.contain,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Menu",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const ListTile(leading: Icon(Icons.home), title: Text("Home")),
            const ListTile(
                leading: Icon(Icons.build), title: Text("Services")),
            const ListTile(
                leading: Icon(Icons.info), title: Text("About Us")),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'My Orders'),
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
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'My Cart',
          ),
        ],
      ),
    );
  }
}
