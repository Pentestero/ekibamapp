import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/services/database_service.dart';
import 'package:provisions/screens/dashboard_screen.dart';
import 'package:provisions/screens/purchase_form_screen.dart';
import 'package:provisions/screens/history_screen.dart';
import 'package:provisions/screens/admin_dashboard_screen.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  
  late List<Widget> _screens;
  late List<NavigationDestination> _destinations;
  late List<NavigationRailDestination> _railDestinations;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().initialize(widget.user);
      _checkAdminStatus();
    });
  }

  void _checkAdminStatus() async {
    final isAdmin = await DatabaseService.instance.isCurrentUserAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _buildNavItems() {
    _screens = [
      DashboardScreen(navigateToHistory: () => _navigateTo(2)),
      const PurchaseFormScreen(),
      const HistoryScreen(),
      if (_isAdmin) const AdminDashboardScreen(),
    ];

    _destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard),
        label: 'Tableau de bord',
      ),
      const NavigationDestination(
        icon: Icon(Icons.add_shopping_cart),
        label: 'Nouvel Achat',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history),
        label: 'Historique',
      ),
      if (_isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    _railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard),
        label: Text('Tableau de bord'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.add_shopping_cart),
        label: Text('Nouvel Achat'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.history),
        label: Text('Historique'),
      ),
      if (_isAdmin)
        const NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings),
          label: Text('Admin'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Build navigation items based on admin status
    _buildNavItems();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  destinations: _railDestinations,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_currentIndex),
                      child: _screens[_currentIndex],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: _destinations,
              backgroundColor: Theme.of(context).colorScheme.surface,
              indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        }
      },
    );
  }
}
