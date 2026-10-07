import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/screens/help_screen.dart';
import 'package:provisions/screens/library_management_screen.dart';
import 'package:provisions/screens/purchase_detail_screen.dart';
import 'package:provisions/screens/reports_screen.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/theme.dart';
import 'package:provisions/widgets/animations.dart';
import 'package:provisions/widgets/dashboard_skeleton.dart';
import 'package:provisions/widgets/filter_panel.dart';
import 'package:provisions/widgets/project_expense_bars.dart';
import 'package:provisions/widgets/supplier_donut_chart.dart';

const Map<AppPalette, (String, Color)> _paletteBadges = {
  AppPalette.blueAmber: ('Bleu-Ambre', Color(0xFFFFB703)),
  AppPalette.purplePink: ('Violet-Rose', Color(0xFF8A38F5)),
  AppPalette.greenTeal: ('Émeraude', Color(0xFF059669)),
  AppPalette.redOrange: ('Cramoisi', Color(0xFFDC2626)),
};

class DashboardScreen extends StatefulWidget {
  final VoidCallback navigateToHistory;
  final VoidCallback? navigateToNewPurchase;
  final bool isAdmin;

  const DashboardScreen({
    super.key,
    required this.navigateToHistory,
    this.navigateToNewPurchase,
    this.isAdmin = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showPaletteSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Choisir une palette'),
          content: Consumer<ThemeController>(
            builder: (context, themeController, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: AppPalette.values.map((palette) {
                  return RadioListTile<AppPalette>(
                    title: Text(palette.toString().split('.').last),
                    value: palette,
                    groupValue: themeController.palette,
                    onChanged: (AppPalette? newPalette) {
                      if (newPalette != null) {
                        themeController.setPalette(newPalette);
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  String _buildInitials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    final first = words.first.substring(0, 1);
    final last = words.length > 1
        ? words.last.substring(0, 1)
        : '';
    return (first + last).toUpperCase();
  }

  int _monthTotal(List<Purchase> purchases, DateTime month) {
    return purchases
        .where((p) => p.date.year == month.year && p.date.month == month.month)
        .fold(0, (sum, p) => sum + p.grandTotal);
  }

  int _monthCount(List<Purchase> purchases, DateTime month) {
    return purchases
        .where((p) => p.date.year == month.year && p.date.month == month.month)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EKIBAM ATELIER',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tableau De Bord',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Recherche rapide',
            visualDensity: VisualDensity.compact,
            onPressed: widget.navigateToHistory,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            visualDensity: VisualDensity.compact,
            onPressed: () => _showSnack('Aucune notification pour le moment.'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: "Menu d'options",
            onSelected: (value) {
              if (value == 'help') {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HelpScreen()));
              } else if (value == 'library') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const LibraryManagementScreen()));
              } else if (value == 'reports') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ReportsScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Aide'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'library',
                child: ListTile(
                  leading: Icon(Icons.library_books_outlined),
                  title: Text('Ma Bibliothèque'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'reports',
                child: ListTile(
                  leading: Icon(Icons.bar_chart_outlined),
                  title: Text('Rapports'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          _buildProfileButton(context),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const DashboardSkeleton();
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: cs.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadPurchases(FilterState()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final currency = currencyFormat;
          final now = DateTime.now();

          return FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeIn,
            ),
            child: RefreshIndicator(
              onRefresh: () => provider.loadPurchases(FilterState()),
              child: SingleChildScrollView(
                key: const ValueKey('dashboard_loaded'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: StaggeredList(
                  itemDelay: const Duration(milliseconds: 50),
                  children: [
                    _buildWelcomeSection(currency),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildKpiSection(provider, now, cs),
                    if (provider.supplierTotals.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildDonutSection(provider, now),
                    ],
                    if (provider.projectTypeTotals.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildProjectSection(provider),
                    ],
                    if (provider.purchases.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildRecentPurchasesSection(provider),
                    ],
                    if (provider.purchases.isEmpty)
                      _buildEmptyState(context),
                    const SizedBox(height: 16),
                    const _SyncBanner(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final name =
            authService.currentUser?.userMetadata?['name'] as String? ??
                'Utilisateur';
        final email = authService.currentUser?.email;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 56),
          child: PopupMenuButton<String>(
            tooltip: 'Profil',
            onSelected: (value) {
              if (value == 'logout') {
                AuthService.instance.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (email != null) ...[
                      const SizedBox(height: 2),
                      Text(email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Se déconnecter'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withAlpha(20),
                child: Text(
                  _buildInitials(name),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(NumberFormat currency) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        final cs = Theme.of(context).colorScheme;
                        final userName =
                            authService.currentUser?.userMetadata?['name'] ??
                                'Utilisateur';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bon retour,',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: cs.primary,
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.secondaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .shadow
                                            .withAlpha(8),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    widget.isAdmin
                                        ? 'Administrateur'
                                        : 'Membre',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: cs.onSecondaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildQuickPills(),
            ],
          ),
          const SizedBox(height: 12),
          _buildPalettePills(),
        ],
      ),
    );
  }

  Widget _buildQuickPills() {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pillButton(
                icon: themeController.mode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                tooltip: 'Basculer le thème',
                onTap: () => themeController.setMode(
                  themeController.mode == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light,
                ),
              ),
              const SizedBox(width: 2),
              _pillButton(
                icon: Icons.palette_outlined,
                tooltip: 'Choisir une palette',
                onTap: () => _showPaletteSelectionDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pillButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withAlpha(8),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildPalettePills() {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        final cs = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Thème :',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
letterSpacing: 0.8,
                    ),
                  ),
              const SizedBox(width: 8),
              ...AppPalette.values.map((palette) {
                final (label, dotColor) = _paletteBadges[palette]!;
                final active = themeController.palette == palette;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => themeController.setPalette(palette),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? cs.primary
                            : cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .shadow
                                .withAlpha(10),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: active
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _quickActionCard(
            label: 'Action directe',
            title: 'Nouvel Achat',
            background: cs.primary,
            foreground: cs.onPrimary,
            circleColor: cs.onPrimary.withAlpha(38),
            icon: Icons.add_shopping_cart,
            onTap: widget.navigateToNewPurchase ?? widget.navigateToHistory,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickActionCard(
            label: 'Scanner IA',
            title: 'Bon de Cde',
            background: cs.secondaryContainer,
            foreground: cs.onSecondaryContainer,
            circleColor: cs.onSecondaryContainer.withAlpha(26),
            icon: Icons.document_scanner,
            onTap: widget.navigateToNewPurchase ?? widget.navigateToHistory,
          ),
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required String label,
    required String title,
    required Color background,
    required Color foreground,
    required Color circleColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foreground.withAlpha(210),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection(
      PurchaseProvider provider, DateTime now, ColorScheme cs) {
    final currency = NumberFormat('#,##0', 'fr_FR');
    final thisMonthTotal = _monthTotal(provider.purchases, now);
    final lastMonthTotal = _monthTotal(
        provider.purchases, DateTime(now.year, now.month - 1));

    final diffPct = lastMonthTotal <= 0
        ? null
        : ((thisMonthTotal - lastMonthTotal) / lastMonthTotal * 100).round();
    final fraction = (lastMonthTotal + thisMonthTotal) <= 0
        ? 0.0
        : (thisMonthTotal /
                (thisMonthTotal + lastMonthTotal))
            .clamp(0.0, 1.0);

    final monthName = DateFormat('MMMM', 'fr_FR').format(now);
    final monthCount = _monthCount(provider.purchases, now);
    final supplierCount = provider.suppliers.length;

    final bigCard = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance_wallet_outlined,
                      color: cs.primary, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Total Dépensé (Mois)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        diffPct == null || diffPct >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 14,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        diffPct == null
                            ? 'nouveau'
                            : '${diffPct >= 0 ? '+' : ''}$diffPct%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    currency.format(thisMonthTotal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -1,
                        ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'XAF',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'dépenses du mois de $monthName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.outline,
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerLowest,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ],
        ),
      ),
    );

    final miniCards = [
      _miniKpiCard(
        icon: Icons.shopping_cart,
        chipText: 'Mensuel',
        chipColor: cs.secondaryContainer,
        chipForeground: cs.onSecondaryContainer,
        value: '$monthCount',
        valueColor: cs.onSurface,
        subtitle: 'commandes ce mois',
      ),
      _miniKpiCard(
        icon: Icons.local_shipping_outlined,
        chipText: 'Base',
        chipColor: cs.tertiaryContainer,
        chipForeground: cs.onTertiaryContainer,
        value: '$supplierCount',
        valueColor: cs.onSurface,
        subtitle: 'fournisseurs enregistrés',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bigCard,
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 360) {
              return Column(
                children: [
                  miniCards[0],
                  const SizedBox(height: 12),
                  miniCards[1],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: miniCards[0]),
                const SizedBox(width: 12),
                Expanded(child: miniCards[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _miniKpiCard({
    required IconData icon,
    required String chipText,
    required Color chipColor,
    required Color chipForeground,
    required String value,
    required Color valueColor,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: chipForeground),
                ),
                Text(
                  chipText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutSection(PurchaseProvider provider, DateTime now) {
    final cs = Theme.of(context).colorScheme;
    final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(now);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Répartition Fournisseurs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                ),
                Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SupplierDonutChart(data: provider.supplierTotals),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSection(PurchaseProvider provider) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat('#,##0', 'fr_FR');
    final total = provider.projectTypeTotals.values
        .fold<int>(0, (sum, v) => sum + v);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dépenses par Projet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                ),
                Text(
                  'Total: ${currency.format(total).length > 7 ? '${currency.format(total ~/ 1000000)}M' : currency.format(total)} XAF',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProjectExpenseBars(data: provider.projectTypeTotals),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPurchasesSection(PurchaseProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Achats Récents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            TextButton(
              onPressed: widget.navigateToHistory,
              style: TextButton.styleFrom(foregroundColor: cs.primary),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...provider.purchases
            .take(2)
            .map((purchase) => _buildRecentPurchaseCard(purchase)),
      ],
    );
  }

  Widget _buildRecentPurchaseCard(Purchase purchase) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat('#,##0', 'fr_FR');
    final itemNames = purchase.items
        .take(3)
        .map((i) => i.subCategory2 ?? i.subCategory1)
        .where((s) => s.isNotEmpty)
        .join(', ');
    final itemsLabel = '${purchase.items.length} '
        'article${purchase.items.length > 1 ? 's' : ''}'
        '${itemNames.isNotEmpty ? ' ($itemNames${purchase.items.length > 3 ? '...' : ''})' : ''}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  PurchaseDetailScreen(purchase: purchase)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            purchase.refDA ?? 'Achat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                  letterSpacing: 0.4,
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('•',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: cs.outline)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            purchase.demander,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _projectTypeBadge(purchase.projectType),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Projet: ${purchase.projectType}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          itemsLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(purchase.grandTotal),
                        maxLines: 1,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                      ),
                      Text(
                        'XAF',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(purchase.date)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.outline,
                        ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Détails',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Icon(Icons.arrow_forward, size: 14, color: cs.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _projectTypeBadge(String projectType) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, dot) = switch (projectType.toLowerCase()) {
      'client' => (cs.secondaryContainer, cs.onSecondaryContainer, cs.secondary),
      'mixte' => (cs.tertiaryContainer, cs.onTertiaryContainer, cs.tertiary),
      'interne' => (cs.primaryContainer, cs.onPrimaryContainer, cs.primary),
      _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            projectType,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ScaleIn(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 40,
                  color: cs.primary.withAlpha(120),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Aucun achat enregistré',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par ajouter votre premier achat',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withAlpha(150),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ScaleTap(
                onTap: widget.navigateToNewPurchase ??
                    widget.navigateToHistory,
                child: FilledButton.tonal(
                  onPressed: widget.navigateToNewPurchase ??
                      widget.navigateToHistory,
                  child: const Text('Nouvel Achat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncBanner extends StatefulWidget {
  const _SyncBanner();

  @override
  State<_SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends State<_SyncBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withAlpha(90),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _pulse,
            child: Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Synchronisation des données : OK',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(_now),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}