import "package:flutter/material.dart";

import "../services/api_service.dart";
import "../widgets/auth_ui.dart";
import "home_screen.dart";
import "more_screen.dart";
import "products_screen.dart";
import "sales_list_screen.dart";

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.api, required this.user});

  final ApiService api;
  final SessionUser user;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  var _index = 0;

  void _openTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.frost,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            api: widget.api,
            user: widget.user,
            onOpenTab: _openTab,
          ),
          SalesListScreen(api: widget.api),
          ProductsScreen(api: widget.api),
          MoreScreen(api: widget.api, user: widget.user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDBEAFE),
        surfaceTintColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: "Sales",
          ),
          NavigationDestination(
            icon: Icon(Icons.icecream_outlined),
            selectedIcon: Icon(Icons.icecream_rounded),
            label: "Products",
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: "More",
          ),
        ],
      ),
    );
  }
}
