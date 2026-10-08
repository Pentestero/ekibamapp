import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, FilteringTextInputFormatter;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:provisions/models/library_item.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/models/supplier.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/screens/help_screen.dart';
import 'package:provisions/screens/library_management_screen.dart';
import 'package:provisions/screens/reports_screen.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/widgets/add_category_dialog.dart';
import 'package:provisions/widgets/add_payment_method_dialog.dart';
import 'package:provisions/widgets/add_requester_dialog.dart';
import 'package:provisions/widgets/add_supplier_dialog.dart';
import 'package:provisions/widgets/animations.dart';
import 'package:provisions/widgets/library_item_selection_dialog.dart';

const int _maxCommentWords = 150;

String? _wordCountValidator(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final words = value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.length > _maxCommentWords) {
    return 'Max $_maxCommentWords mots autorisés. Actuellement: ${words.length} mots.';
  }
  return null;
}

int _countWords(String? value) {
  if (value == null || value.trim().isEmpty) return 0;
  return value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

String _buildInitials(String name) {
  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  final first = words.first.substring(0, 1);
  final last = words.length > 1 ? words.last.substring(0, 1) : '';
  return (first + last).toUpperCase();
}

class PurchaseFormScreen extends StatefulWidget {
  final Function(bool isEditing)? onSubmissionSuccess;
  const PurchaseFormScreen({super.key, this.onSubmissionSuccess});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _clientNameController = TextEditingController();
  final bool _isAiProcessing = false;

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false, bool isWarning = false}) {
    final cs = Theme.of(context).colorScheme;
    final Color backgroundColor;
    final IconData iconData;
    final Color textColor;

    if (isError) {
      backgroundColor = cs.error;
      iconData = Icons.error_outline;
      textColor = cs.onError;
    } else if (isWarning) {
      backgroundColor = cs.secondaryContainer;
      iconData = Icons.warning_amber_rounded;
      textColor = cs.onSecondaryContainer;
    } else {
      backgroundColor = cs.primary;
      iconData = Icons.check_circle_outline;
      textColor = cs.onPrimary;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(iconData, color: textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  Future<void> _scanInvoiceWithAI() async {
    if (mounted) {
      _showSnackBar(
        context,
        "Cette fonctionnalité nécessite un abonnement mensuel pour l'utiliser.",
        isWarning: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PurchaseProvider>();
      if (!provider.isEditing) {
        provider.clearForm();
      }
    });
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _clientNameController.dispose();
    super.dispose();
  }

  void _showAddRequesterDialog() {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PurchaseProvider>(),
        child: const AddRequesterDialog(),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PurchaseProvider>(),
        child: const AddPaymentMethodDialog(),
      ),
    );
  }

  void _onProjectTypeChanged(PurchaseProvider provider, String value) {
    provider.updatePurchaseHeader(projectType: value);
    if (value != 'Client' && value != 'Mixte') {
      _clientNameController.clear();
      provider.updatePurchaseHeader(clientName: '');
    }
  }

  InputDecoration _fieldDecoration(BuildContext context,
      {required String label,
      IconData? icon,
      String? suffixText,
      String? helperText}) {
    final cs = Theme.of(context).colorScheme;
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant, width: 1),
    );
    final focus = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 2),
    );
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon:
          icon != null ? Icon(icon, size: 20, color: cs.tertiary) : null,
      suffixText: suffixText,
      filled: true,
      fillColor: cs.surfaceContainerLow,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: base,
      focusedBorder: focus,
      border: base,
      errorBorder: base.copyWith(borderSide: BorderSide(color: cs.error)),
      focusedErrorBorder:
          focus.copyWith(borderSide: BorderSide(color: cs.error)),
    );
  }

  Widget _buildSquareAddButton(
    BuildContext context, {
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(Icons.add, color: cs.primary, size: 24),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notifications',
        visualDensity: VisualDensity.compact,
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(
              content: Text('Aucune notification pour le moment.'),
              behavior: SnackBarBehavior.floating,
            ));
        },
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: "Menu d'options",
        onSelected: (value) {
          if (value == 'help') {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HelpScreen()));
          } else if (value == 'library') {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LibraryManagementScreen()));
          } else if (value == 'reports') {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
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
      _buildProfileButton(),
    ];
  }

  Widget _buildProfileButton() {
    final cs = Theme.of(context).colorScheme;
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
                backgroundColor: cs.primary.withValues(alpha: 0.2),
                child: Text(
                  _buildInitials(name),
                  style: TextStyle(
                    color: cs.primary,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return Row(
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
                        provider.isEditing ? 'Modifier l\'achat' : 'Nouvel Achat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: _buildAppBarActions(),
      ),
      body: Stack(
        children: [
          Consumer<PurchaseProvider>(
            builder: (context, provider, child) {
              if (_commentsController.text != provider.purchaseBuilder.comments) {
                _commentsController.text = provider.purchaseBuilder.comments;
              }
              if (_clientNameController.text !=
                  (provider.purchaseBuilder.clientName ?? '')) {
                _clientNameController.text =
                    provider.purchaseBuilder.clientName ?? '';
              }

              if (provider.isLoading &&
                  provider.requesters.isEmpty &&
                  !provider.isEditing) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAiBanner(context, provider),
                      const SizedBox(height: 16),
                      _buildGeneralInfoCard(context, provider),
                      const SizedBox(height: 16),
                      _buildItemsSection(context, provider),
                      const SizedBox(height: 16),
                      _buildGrandTotalCard(context, provider),
                      const SizedBox(height: 24),
                      _buildSubmitButton(context, provider),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isAiProcessing)
            Container(
              color: Color(0xFF141B2B).withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Analyse du document en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiBanner(BuildContext context, PurchaseProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primaryContainer, cs.surfaceContainerHigh],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.document_scanner,
                    size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Analyser un document',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'SMART OCR ATELIER',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: cs.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Extraction auto : articles, PU et montants en devises CEMAC.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.primaryFixedDim,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBannerButton(
                  context,
                  icon: Icons.photo_camera,
                  label: 'Scanner Facture',
                  solid: true,
                  onTap: _scanInvoiceWithAI,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBannerButton(
                  context,
                  icon: Icons.visibility,
                  label: 'Aperçu (0 reçu)',
                  solid: false,
                  onTap: () => _showSnackBar(
                    context,
                    'Aucun document scanné pour le moment.',
                    isWarning: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool solid,
  }) {
    final cs = Theme.of(context).colorScheme;
    final background = solid
        ? cs.surfaceContainerLowest
        : cs.secondaryContainer.withValues(alpha: 0.3);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: solid ? cs.primary : Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: solid ? cs.primary : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(BuildContext context, PurchaseProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return _infoCard(
      context,
      header: _buildCardHeader(
        context,
        accent: cs.primary,
        title: 'Informations Générales',
        subtitle: 'Section 1/2',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildLockedField(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Date d\'engagement',
                  value: DateFormat('dd/MM/yyyy').format(provider.purchaseBuilder.date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLockedField(
                  context,
                  icon: Icons.person,
                  label: 'Demandeur Opérationnel',
                  value: provider.purchaseBuilder.demander.isNotEmpty
                      ? '${provider.purchaseBuilder.demander} (Session active)'
                      : 'Session active',
                  small: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: provider.purchaseBuilder.miseADBudget,
                  isExpanded: true,
                  decoration: _fieldDecoration(
                    context,
                    label: 'Destinataire / Imputation Budget',
                    icon: Icons.account_balance_wallet,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Aucun'),
                    ),
                    ...provider.requesters
                        .map((r) => DropdownMenuItem(value: r, child: Text(r))),
                  ],
                  onChanged: (value) =>
                      provider.updatePurchaseHeader(miseADBudget: value),
                ),
              ),
              const SizedBox(width: 8),
              _buildSquareAddButton(
                context,
                tooltip: 'Ajouter un centre de coût',
                onTap: _showAddRequesterDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProjectTypeSegmented(context, provider),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:
                (provider.purchaseBuilder.projectType == 'Client' ||
                        provider.purchaseBuilder.projectType == 'Mixte')
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TextFormField(
                          controller: _clientNameController,
                          decoration: _fieldDecoration(
                            context,
                            label: 'Nom du Client / Réf. Contrat *',
                            icon: Icons.business,
                            helperText:
                                'Ex: SABC Brasseries - Réf: OT-8849',
                          ),
                          onChanged: (value) =>
                              provider.updatePurchaseHeader(clientName: value),
                          validator: (value) {
                            if ((provider.purchaseBuilder.projectType ==
                                        'Client' ||
                                    provider.purchaseBuilder.projectType ==
                                        'Mixte') &&
                                (value == null || value.isEmpty)) {
                              return 'Le nom du client/projet est requis';
                            }
                            return null;
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: provider.paymentMethods
                          .contains(provider.purchaseBuilder.paymentMethod)
                      ? provider.purchaseBuilder.paymentMethod
                      : null,
                  isExpanded: true,
                  decoration: _fieldDecoration(
                    context,
                    label: 'Mode de Paiement Prévu',
                    icon: Icons.payments_outlined,
                  ),
                  items: provider.paymentMethods
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) =>
                      provider.updatePurchaseHeader(paymentMethod: value),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Champ requis' : null,
                ),
              ),
              const SizedBox(width: 8),
              _buildSquareAddButton(
                context,
                tooltip: 'Ajouter un moyen de paiement',
                onTap: _showAddPaymentMethodDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentsController,
            decoration: _fieldDecoration(
              context,
              label: 'Justification / Remarques',
              icon: Icons.comment_outlined,
            ).copyWith(
              helperText:
                  '${_countWords(provider.purchaseBuilder.comments)} / $_maxCommentWords mots autorisés',
              helperStyle: _countWords(provider.purchaseBuilder.comments) >
                      _maxCommentWords
                  ? TextStyle(color: cs.error, fontWeight: FontWeight.w700)
                  : null,
            ),
            onChanged: (value) =>
                provider.updatePurchaseHeader(comments: value),
            validator: _wordCountValidator,
            maxLines: 3,
            minLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectTypeSegmented(
      BuildContext context, PurchaseProvider provider) {
    final cs = Theme.of(context).colorScheme;
    final options = const [
      ('Interne Atelier', 'Interne'),
      ('Client', 'Client'),
      ('Mixte', 'Mixte'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Affectation du Projet',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: options.map((item) {
              final (label, value) = item;
              final isSelected =
                  provider.purchaseBuilder.projectType == value;
              return Expanded(
                child: ScaleTap(
                  hapticFeedback: true,
                  onTap: () => _onProjectTypeChanged(provider, value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.surfaceContainerLowest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? cs.primary
                                : cs.onSurfaceVariant,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(BuildContext context, PurchaseProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return _infoCard(
      context,
      header: _buildCardHeader(
        context,
        accent: cs.secondaryContainer,
        title: 'Articles Commandés',
        subtitle: 'Section 2/2',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${provider.itemsBuilder.length} Article${provider.itemsBuilder.length > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAddItemButton(
                  context,
                  icon: Icons.add_circle,
                  label: '+ Ajouter article',
                  background: cs.secondaryContainer,
                  foreground: cs.onSecondaryContainer,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final error = provider.addNewItem();
                    if (error != null) {
                      _showSnackBar(context, error, isWarning: true);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAddItemButton(
                  context,
                  icon: Icons.menu_book,
                  label: 'Bibliothèque',
                  background: cs.primary,
                  foreground: cs.onPrimary,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final selectedItem = await showDialog<LibraryItem>(
                      context: context,
                      builder: (ctx) => ChangeNotifierProvider.value(
                        value: provider,
                        child: const LibraryItemSelectionDialog(),
                      ),
                    );
                    if (selectedItem != null) {
                      provider.addItemFromLibrary(selectedItem);
                      if (!context.mounted) return;
                      _showSnackBar(
                          context, 'Article ajouté depuis la bibliothèque.');
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.itemsBuilder.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 40, color: cs.tertiary),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur "Ajouter article" ou "Bibliothèque" pour commencer.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            child: provider.itemsBuilder.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    key: const ValueKey('items_list'),
                    children: provider.itemsBuilder.asMap().entries.map((entry) {
                      return ScaleIn(
                        key: ValueKey(
                            'item_${provider.itemsBuilder[entry.key].localId}'),
                        child: _PurchaseItemCard(
                          key: ValueKey(provider.itemsBuilder[entry.key]),
                          index: entry.key,
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrandTotalCard(BuildContext context, PurchaseProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [cs.primary, cs.primaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified,
                        size: 18, color: cs.secondaryContainer),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'GRAND TOTAL REQUISITION',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Net à décaisser (TTC)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onPrimary.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    NumberFormat('#,##0', 'fr_FR')
                        .format(provider.grandTotalBuilder),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
                Text(
                  'XAF CEMAC',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.secondaryContainer,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, PurchaseProvider provider) {
    final cs = Theme.of(context).colorScheme;
    final isSaving = provider.isLoading;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondaryContainer],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : () => _submitForm(context, provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
        icon: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.assignment_turned_in, size: 22),
        label: Text(isSaving
            ? 'Enregistrement...'
            : (provider.isEditing ? 'Mettre à jour l\'achat' : 'Enregistrer l\'Achat')),
      ),
    );
  }

  Future<void> _submitForm(
      BuildContext context, PurchaseProvider provider) async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        provider.itemsBuilder.isEmpty ||
        provider.grandTotalBuilder <= 0) {
      if (provider.itemsBuilder.isEmpty) {
        _showSnackBar(context, 'Veuillez ajouter au moins un article.',
            isWarning: true);
      } else if (provider.grandTotalBuilder <= 0) {
        _showSnackBar(context,
            'Le montant total de l\'achat doit être supérieur à zéro.',
            isError: true);
      }
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final amount =
        '${NumberFormat('#,##0', 'fr_FR').format(provider.grandTotalBuilder)} XAF';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: cs.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.task_alt, size: 32, color: cs.secondary),
                ),
                const SizedBox(height: 16),
                Text(
                  provider.isEditing
                      ? 'Confirmer la mise à jour'
                      : 'Transmission pour Validation',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.isEditing
                      ? 'Le bon d\'achat ${provider.purchaseBuilder.refDA ?? ''} sera mis à jour.'
                      : 'Le bon d\'achat d\'un montant de $amount sera envoyé au Responsable Logistique.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: const Text('Confirmer l\'envoi',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Modifier la commande'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    Purchase? resultPurchase;
    if (provider.isEditing) {
      resultPurchase = await provider.updatePurchase();
    } else {
      resultPurchase = await provider.addPurchase();
    }

    if (!context.mounted) return;

    if (resultPurchase != null) {
      final successMessage = provider.isEditing
          ? 'Mise à jour réussie avec succès ! N°: ${resultPurchase.refDA}'
          : 'Achat enregistré avec succès ! N°: ${resultPurchase.refDA}';
      _showSnackBar(context, successMessage);
      widget.onSubmissionSuccess?.call(provider.isEditing);
      provider.clearForm();
    } else {
      final isNetworkError = provider.errorMessage.contains('Failed to fetch');
      final errorMessage = isNetworkError
          ? 'Erreur de connexion. Impossible d\'enregistrer.'
          : 'Erreur: ${provider.errorMessage}';
      _showSnackBar(context, errorMessage, isError: true);
    }
  }

  Widget _infoCard(BuildContext context,
      {required Widget header, required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context, {
    required Color accent,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
        if (trailing != null) trailing,
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.tertiary,
                letterSpacing: 0.4,
              ),
        ),
      ],
    );
  }

  Widget _buildLockedField(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool small = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: small ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                ),
              ),
              if (small) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock_outline,
                    size: 14, color: cs.tertiary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseItemCard extends StatefulWidget {
  final int index;
  const _PurchaseItemCard({super.key, required this.index});

  @override
  State<_PurchaseItemCard> createState() => _PurchaseItemCardState();
}

class _PurchaseItemCardState extends State<_PurchaseItemCard> {
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late final TextEditingController _commentController;
  bool _showComment = false;

  @override
  void initState() {
    super.initState();
    final item = context.read<PurchaseProvider>().itemsBuilder[widget.index];
    _quantityController =
        TextEditingController(text: _formatQty(item.quantity));
    _unitController = TextEditingController(text: item.unit ?? '');
    _priceController = TextEditingController(text: item.unitPrice.toString());
    _commentController =
        TextEditingController(text: item.comment ?? '');
    _showComment = (item.comment ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    return (qty % 1 == 0) ? qty.toInt().toString() : qty.toString();
  }

  double _parseQty(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0.0;

  Future<void> _selectExpenseDate(BuildContext context) async {
    final provider = context.read<PurchaseProvider>();
    final item = provider.itemsBuilder[widget.index];
    final purchaseCreationDate = provider.purchaseBuilder.date;
    final lastSelectableDate = DateTime.now().isBefore(purchaseCreationDate)
        ? DateTime.now()
        : purchaseCreationDate;

    DateTime initialDate = item.expenseDate;
    if (initialDate.isAfter(lastSelectableDate)) {
      initialDate = lastSelectableDate;
    }
    if (initialDate.isBefore(DateTime(2020))) {
      initialDate = DateTime(2020);
    }

    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: lastSelectableDate,
    );

    if (newDate != null) {
      provider.updateItem(widget.index, expenseDate: newDate);
    }
  }

  Future<void> _showAddSupplierDialog() async {
    final provider = context.read<PurchaseProvider>();
    final newSupplier = await showDialog<Supplier>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const AddSupplierDialog(),
      ),
    );
    if (newSupplier != null && mounted) {
      provider.updateItem(widget.index, supplierId: newSupplier.id);
    }
  }

  Future<void> _pickSupplier() async {
    final provider = context.read<PurchaseProvider>();
    final item = provider.itemsBuilder[widget.index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Fournisseur',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Divider(
                      color:
                          Theme.of(context).colorScheme.outlineVariant),
                  Flexible(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        for (final supplier in provider.suppliers) ...[
                          ListTile(
                            leading: Icon(
                              item.supplierId == supplier.id
                                  ? Icons.radio_button_checked
                                  : Icons.store_outlined,
                              color: item.supplierId == supplier.id
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.tertiary,
                            ),
                            title: Text(supplier.name),
                            onTap: () {
                              final isNone = supplier.id == -1;
                              provider.updateItem(widget.index,
                                  supplierId:
                                      isNone ? null : supplier.id);
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                          Divider(
                              height: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant),
                        ],
                        ListTile(
                          leading: Icon(Icons.add_circle,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text('Créer un nouveau fournisseur',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600)),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _showAddSupplierDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PurchaseProvider>(),
        child: const AddCategoryDialog(),
      ),
    );
  }

  Future<void> _pickCategory(
      BuildContext context, PurchaseProvider provider) async {
    final cs = Theme.of(context).colorScheme;
    final categories = provider.categories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Aucune catégorie disponible. Ajoutez-en une via le +.')),
      );
      return;
    }

    final item = provider.itemsBuilder[widget.index];
    String? selCat =
        categories.containsKey(item.category) ? item.category : categories.keys.first;

    List<String> sub1For(String? c) {
      if (c == null) return <String>[];
      return categories[c]?.keys.toList() ?? <String>[];
    }

    List<String> sub2For(String? c, String? s1) {
      if (c == null || s1 == null) return <String>[];
      return categories[c]?[s1] ?? <String>[];
    }

    String? selSub1 = sub1For(selCat).contains(item.subCategory1)
        ? item.subCategory1
        : (sub1For(selCat).isNotEmpty ? sub1For(selCat).first : '');
    List<String> sub2List = sub2For(selCat, selSub1);
    String? selSub2 = sub2List.contains(item.subCategory2)
        ? item.subCategory2
        : (sub2List.isNotEmpty ? sub2List.first : null);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sub1List = sub1For(selCat);
            final sub2Items = sub2For(selCat, selSub1);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Catégorie',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selCat,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Catégorie'),
                      items: categories.keys
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setSheetState(() {
                        selCat = value;
                        final s1 = sub1For(value);
                        selSub1 = s1.isNotEmpty ? s1.first : '';
                        final s2 = sub2For(value, selSub1);
                        selSub2 = s2.isNotEmpty ? s2.first : null;
                      }),
                    ),
                    if (sub1List.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue:
                            sub1List.contains(selSub1) ? selSub1 : sub1List.first,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Sous-catégorie 1'),
                        items: sub1List
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) => setSheetState(() {
                          selSub1 = value;
                          final s2 = sub2For(selCat, value);
                          selSub2 = s2.isNotEmpty ? s2.first : null;
                        }),
                      ),
                    ],
                    if (sub2Items.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: sub2Items.contains(selSub2)
                            ? selSub2
                            : sub2Items.first,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Sous-catégorie 2 / Article'),
                        items: sub2Items
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) =>
                            setSheetState(() => selSub2 = value),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selCat != null) {
                            provider.updateItem(
                              widget.index,
                              category: selCat,
                              subCategory1: selSub1 ?? '',
                              subCategory2: selSub2,
                            );
                          }
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Valider'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(String title) {
    final cs = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: cs.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.delete_forever, size: 28, color: cs.error),
                ),
                const SizedBox(height: 16),
                Text(
                  'Supprimer cet article ?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.tertiary),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<PurchaseProvider>();
    final item = provider.itemsBuilder[widget.index];

    final rawProductName = item.subCategory2 != null &&
            item.subCategory2!.isNotEmpty
        ? item.subCategory2!
        : (item.subCategory1.isNotEmpty
            ? item.subCategory1
            : item.category);
    final productName =
        rawProductName.trim().isEmpty ? 'Nouvel article' : rawProductName;

    final currencyFormat = NumberFormat('#,##0', 'fr_FR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIGNE ${(widget.index + 1).toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      productName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
                tooltip: 'Supprimer',
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final confirmed = await _confirmDelete(productName);
                  if (confirmed == true && mounted) {
                    provider.removeItem(widget.index);
                  }
                },
              ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _pickCategory(context, provider),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.category_outlined, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: item.category.isEmpty
                        ? Text(
                            'Choisir une catégorie',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _categoryChip(context, item.category,
                                  icon: Icons.build),
                              if (item.subCategory1.isNotEmpty) ...[
                                Icon(Icons.chevron_right,
                                    size: 14, color: cs.outlineVariant),
                                _categoryChip(context, item.subCategory1),
                              ],
                              if (item.subCategory2 != null &&
                                  item.subCategory2!.isNotEmpty) ...[
                                Icon(Icons.chevron_right,
                                    size: 14, color: cs.outlineVariant),
                                _categoryChip(context, item.subCategory2!,
                                    selected: true),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 16, color: cs.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Supplier row
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _pickSupplier,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.store_outlined,
                      size: 16, color: cs.tertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Fournisseur : ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.supplierName ?? 'Aucun',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 16, color: cs.primary),
                ],
              ),
            ),
          ),
          // Expense date + category quick edit
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _selectExpenseDate(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month,
                            size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Date: ${DateFormat('dd/MM/yyyy').format(item.expenseDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showAddCategoryDialog,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Catégorie'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildNumberFields(context, provider, item, currencyFormat, cs),
          const SizedBox(height: 8),
          // Comment toggle
          if (!_showComment)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showComment = true),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.comment_outlined, size: 16),
                label: const Text('Commentaire'),
              ),
            )
          else
            TextFormField(
              controller: _commentController,
              decoration: _commentDecoration(context).copyWith(
                helperText:
                    '${_countWords(item.comment)} / $_maxCommentWords mots',
                helperStyle: _countWords(item.comment) > _maxCommentWords
                    ? TextStyle(color: cs.error, fontWeight: FontWeight.w700)
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<PurchaseProvider>()
                    .updateItemComment(widget.index, value);
                setState(() {});
              },
              validator: _wordCountValidator,
              maxLines: 2,
              minLines: 1,
            ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Article:',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Flexible(
                  child: Text(
                    '${currencyFormat.format(item.total)} XAF',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(BuildContext context, String label,
      {IconData? icon, bool selected = false}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? cs.primary.withValues(alpha: 0.1)
            : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  InputDecoration _commentDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant, width: 1),
    );
    return InputDecoration(
      labelText: 'Commentaire (article)',
      prefixIcon: Icon(Icons.comment_outlined,
          size: 18, color: cs.tertiary),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: base,
      focusedBorder: base.copyWith(borderSide: BorderSide(color: cs.primary, width: 2)),
      border: base,
    );
  }

  Widget _buildNumberFields(
    BuildContext context,
    PurchaseProvider provider,
    PurchaseItem item,
    NumberFormat currencyFormat,
    ColorScheme cs,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tightWidth = constraints.maxWidth < 420;
        final gridColor = cs.surfaceContainerLowest;

        Widget quantityCell() => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gridColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantité',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.tertiary,
                          )),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 6),
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]+'))
                          ],
                          onChanged: (value) {
                            provider.updateItem(widget.index,
                                quantity: _parseQty(value));
                          },
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Requis';
                            }
                            final qty = _parseQty(value);
                            if (qty <= 0) {
                              return '> 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      Text('·', style: TextStyle(color: cs.tertiary)),
                      SizedBox(
                        width: tightWidth ? 56 : 44,
                        child: TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 6),
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.tertiary),
                          onChanged: (value) => provider.updateItem(
                              widget.index,
                              unit: value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

        Widget priceCell() => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gridColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prix Unitaire',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.tertiary,
                          )),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 6),
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            provider.updateItem(widget.index,
                                unitPrice: int.tryParse(value) ?? 0);
                          },
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                int.tryParse(value) == 0) {
                              return 'Requis';
                            }
                            return null;
                          },
                        ),
                      ),
                      Text('XAF',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.tertiary)),
                    ],
                  ),
                ],
              ),
            );

        Widget subtotalCell() => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gridColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sous-Total',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.tertiary,
                          )),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(item.total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                  ),
                  Text('XAF',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.primary)),
                ],
              ),
            );

        if (tightWidth) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: quantityCell()),
                  const SizedBox(width: 8),
                  Expanded(child: priceCell()),
                ],
              ),
              const SizedBox(height: 8),
              subtotalCell(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: quantityCell()),
            const SizedBox(width: 8),
            Expanded(child: priceCell()),
            const SizedBox(width: 8),
            Expanded(child: subtotalCell()),
          ],
        );
      },
    );
  }
}