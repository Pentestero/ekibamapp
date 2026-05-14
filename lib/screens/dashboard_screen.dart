import 'package:provisions/widgets/filter_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/widgets/analytics_card.dart';
import 'package:provisions/widgets/supplier_chart.dart';
import 'package:provisions/widgets/project_type_chart.dart';
import 'package:intl/intl.dart';
import 'package:provisions/screens/help_screen.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/theme.dart';
import 'package:provisions/widgets/dashboard_skeleton.dart';
import 'package:provisions/screens/library_management_screen.dart';
import 'package:provisions/screens/reports_screen.dart';
import 'package:provisions/widgets/animations.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback navigateToHistory;
  const DashboardScreen({super.key, required this.navigateToHistory});

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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
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
            const Text('Tableau de bord'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'help') {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HelpScreen()));
              } else if (value == 'toggleTheme') {
                final controller = context.read<ThemeController>();
                controller.setMode(controller.mode == ThemeMode.light
                    ? ThemeMode.dark
                    : ThemeMode.light);
              } else if (value == 'selectPalette') {
                _showPaletteSelectionDialog(context);
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
                value: 'toggleTheme',
                child: ListTile(
                  leading: Icon(Icons.brightness_6),
                  title: Text('Basculer Thème'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'selectPalette',
                child: ListTile(
                  leading: Icon(Icons.palette),
                  title: Text('Choisir Palette'),
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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await AuthService.instance.signOut();
            },
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return DashboardSkeleton();
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: cs.error,
                  ),
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

          return FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeIn,
            ),
            child: RefreshIndicator(
              onRefresh: () => provider.loadPurchases(FilterState()),
              child: SingleChildScrollView(
                key: const ValueKey('dashboard_loaded'),
                padding: const EdgeInsets.all(16),
                child: StaggeredList(
                  itemDelay: const Duration(milliseconds: 50),
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Consumer<AuthService>(
                          builder: (context, authService, child) {
                            final userName = authService
                                    .currentUser?.userMetadata?['name'] ??
                                'Utilisateur';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bon retour,',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: cs.onSurface.withAlpha(150),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: cs.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          AnalyticsCard(
                            title: 'Total Dépensé',
                            value:
                                '${NumberFormat('#,##0', 'fr_FR').format(provider.totalSpent)} XAF',
                            icon: Icons.account_balance_wallet,
                            color: cs.primary,
                          ),
                          AnalyticsCard(
                            title: 'Achats Totaux',
                            value: provider.totalPurchases.toString(),
                            icon: Icons.shopping_cart,
                            color: cs.secondary,
                          ),
                        ];
                        if (constraints.maxWidth < 600) {
                          return Column(children: [
                            ScaleTap(child: cards[0]),
                            const SizedBox(height: 12),
                            ScaleTap(child: cards[1]),
                          ]);
                        }
                        return Row(children: [
                          Expanded(child: ScaleTap(child: cards[0])),
                          const SizedBox(width: 12),
                          Expanded(child: ScaleTap(child: cards[1])),
                        ]);
                      },
                    ),
                    const SizedBox(height: 28),
                    if (provider.supplierTotals.isNotEmpty) ...[
                      _buildSectionHeader(
                          context, 'Répartition par Fournisseur'),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: SupplierChart(data: provider.supplierTotals),
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (provider.projectTypeTotals.isNotEmpty) ...[
                      _buildSectionHeader(
                          context, 'Répartition par Type de Projet'),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child:
                            ProjectTypeChart(data: provider.projectTypeTotals),
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (provider.purchases.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(context, 'Achats Récents'),
                          TextButton(
                            onPressed: widget.navigateToHistory,
                            style: TextButton.styleFrom(
                              foregroundColor: cs.primary,
                            ),
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...provider.purchases.take(2).map((purchase) => ScaleTap(
                            child: Card(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withAlpha(20),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.shopping_cart,
                                      color: cs.primary, size: 22),
                                ),
                                title: Text(
                                  '${purchase.refDA ?? 'Achat'} de ${purchase.items.length} article(s)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Demandeur: ${purchase.demander} • Projet: ${purchase.projectType}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onSurface.withAlpha(150),
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${currencyFormat.format(purchase.grandTotal)} XAF',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: cs.primary,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(purchase.date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ],
                    if (provider.purchases.isEmpty)
                      ScaleIn(
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
                                    borderRadius:
                                        BorderRadius.circular(24),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Commencez par ajouter votre premier achat',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: cs.onSurface.withAlpha(150),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Row(
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
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
