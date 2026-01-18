import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/widgets/admin_dashboard_skeleton.dart';
import 'package:provisions/services/excel_service.dart';
import 'package:provisions/screens/history_screen.dart'; // Re-using PurchaseCard
import 'package:provisions/widgets/analytics_card.dart';
import 'package:provisions/screens/purchase_detail_screen.dart'; // Import PurchaseDetailScreen
import 'package:provisions/widgets/admin_analytics_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final AnimationController _contentController;
  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadAllPurchases();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _contentFadeAnimation =
        CurvedAnimation(parent: _contentController, curve: Curves.easeIn);
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic));
    _contentController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');
    final provider = context.watch<PurchaseProvider>();

    // Filter purchases based on search query
    final filteredPurchases = provider.allPurchases.where((purchase) {
      final query = _searchQuery.toLowerCase();
      return (purchase.refDA?.toLowerCase().contains(query) ?? false) ||
             (purchase.demander.toLowerCase().contains(query)) ||
             (purchase.clientName?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadAllPurchases(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par Ref DA, Demandeur ou Client...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: provider.isLoading
          ? AdminDashboardSkeleton()          : FadeTransition(              opacity: _contentFadeAnimation,
              child: SlideTransition(
                position: _contentSlideAnimation,
                child: RefreshIndicator(
                  onRefresh: () => provider.loadAllPurchases(),
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Key Metrics
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            return Column(
                              children: [
                                AnalyticsCard(
                                  title: 'Total Dépensé (Tous)',
                                  value:
                                      '${currencyFormat.format(provider.grandTotalSpentAll)} XAF',
                                  icon: Icons.monetization_on,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                AnalyticsCard(
                                  title: 'Nombre d\'Achats (Tous)',
                                  value:
                                      provider.totalNumberOfPurchasesAll.toString(),
                                  icon: Icons.receipt_long,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Expanded(
                                  child: AnalyticsCard(
                                    title: 'Total Dépensé (Tous)',
                                    value:
                                        '${currencyFormat.format(provider.grandTotalSpentAll)} XAF',
                                    icon: Icons.monetization_on,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AnalyticsCard(
                                    title: 'Nombre d\'Achats (Tous)',
                                    value:
                                        provider.totalNumberOfPurchasesAll.toString(),
                                    icon: Icons.receipt_long,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      // List of all purchases
                      Text(
                        'Toutes les Demandes d\'Achat',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Divider(height: 20),
                      if (filteredPurchases.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                                'Aucun achat trouvé correspondant à la recherche.'),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredPurchases.length,
                          itemBuilder: (context, index) {
                            final purchase = filteredPurchases[index];
                            // We can reuse the PurchaseCard from history_screen
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PurchaseDetailScreen(purchase: purchase),
                                  ),
                                );
                              },
                              child: PurchaseCard(purchase: purchase),
                            );
                          },
                        ),
                      const SizedBox(height: 24),

                      // Analytics Charts
                      AdminAnalyticsChart(
                        title: 'Top 5 Dépenseurs (Admin)',
                        data: provider.topSpenders,
                      ),
                      AdminAnalyticsChart(
                        title: 'Top Méthodes de Paiement (Admin)',
                        data: provider.topPaymentMethods,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await ExcelService.shareExcelReport(
              provider.allPurchases); // Export all, not just filtered
        },
        icon: const Icon(Icons.file_download),
        label: const Text('Exporter tout (Excel)'),
      ),
    );
  }
}
