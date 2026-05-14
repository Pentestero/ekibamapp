import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/services/database_service.dart';
import 'package:provisions/screens/dashboard_screen.dart';
import 'package:provisions/screens/purchase_form_screen.dart';
import 'package:provisions/screens/history_screen.dart';
import 'package:provisions/screens/admin_dashboard_screen.dart';
import 'package:provisions/models/purchase.dart';

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

  void _onEditPurchaseFromHistory(Purchase purchase) {
    setState(() {
      _currentIndex = 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchaseForEditing(purchase);
    });
  }

  void _handlePurchaseSubmissionSuccess(bool isEditing) {
    debugPrint(
        'HomePage: _handlePurchaseSubmissionSuccess called with isEditing: $isEditing');
    if (mounted) {
      setState(() {
        final oldIndex = _currentIndex;
        if (isEditing) {
          _currentIndex = 2;
          debugPrint(
              'HomePage: _handlePurchaseSubmissionSuccess: Changing _currentIndex from $oldIndex to $_currentIndex (History)');
        } else {
          _currentIndex = 0;
          debugPrint(
              'HomePage: _handlePurchaseSubmissionSuccess: Changing _currentIndex from $oldIndex to $_currentIndex (Dashboard)');
        }
      });
    }
  }

  void _buildNavItems() {
    _screens = [
      DashboardScreen(navigateToHistory: () => _navigateTo(2)),
      PurchaseFormScreen(onSubmissionSuccess: _handlePurchaseSubmissionSuccess),
      HistoryScreen(onEditPurchase: _onEditPurchaseFromHistory),
      if (_isAdmin) const AdminDashboardScreen(),
    ];
    _destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Tableau de bord',
      ),
      const NavigationDestination(
        icon: Icon(Icons.add_shopping_cart_outlined),
        selectedIcon: Icon(Icons.add_shopping_cart),
        label: 'Nouvel Achat',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'Historique',
      ),
      if (_isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    _railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Tableau de bord'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.add_shopping_cart_outlined),
        selectedIcon: Icon(Icons.add_shopping_cart),
        label: Text('Nouvel Achat'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: Text('Historique'),
      ),
      if (_isAdmin)
        const NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: Text('Admin'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.03, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
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
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
            bottomNavigationBar: NavigationBar(
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: _destinations,
            ),
          );
        }
      },
    );
  }
}
