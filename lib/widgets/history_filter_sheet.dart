import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/filter_panel.dart';

class HistoryFilterSheet extends StatefulWidget {
  final FilterState initialFilters;
  final void Function(FilterState newFilters) onFilterChanged;

  const HistoryFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onFilterChanged,
  });

  @override
  State<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<HistoryFilterSheet> {
  late FilterState _draft;
  late DateTime? _customStart;
  late DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilters;
    _customStart = _draft.startDate;
    _customEnd = _draft.endDate;
  }

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  void _applyPreset({required DateTime start, required DateTime end}) {
    setState(() {
      _draft = _draft.copyWith(
        startDate: _startOfDay(start),
        endDate: _endOfDay(end),
      );
      _customStart = _draft.startDate;
      _customEnd = _draft.endDate;
    });
  }

  void _applyThisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _applyPreset(start: monday, end: monday.add(const Duration(days: 6)));
  }

  void _applyThisMonth() {
    final now = DateTime.now();
    _applyPreset(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  void _applyThisQuarter() {
    final now = DateTime.now();
    final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    final start = DateTime(now.year, quarterStartMonth, 1);
    final end = DateTime(now.year, quarterStartMonth + 3, 0);
    _applyPreset(start: start, end: end);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: (_customStart != null && _customEnd != null)
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );
    if (picked != null) {
      _applyPreset(start: picked.start, end: picked.end);
    }
  }

  bool get _hasCustomRange =>
      _customStart != null || _customEnd != null;

  bool _matchesPreset(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    final s = _startOfDay(start);
    final e = _endOfDay(end);
    return _draft.startDate != null &&
        _draft.endDate != null &&
        _startOfDay(_draft.startDate!).isAtSameMomentAs(s) &&
        _endOfDay(_draft.endDate!).isAtSameMomentAs(e);
  }

  bool _isThisWeekSelected() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return _matchesPreset(monday, monday.add(const Duration(days: 6)));
  }

  bool _isThisMonthSelected() {
    final now = DateTime.now();
    return _matchesPreset(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0),
    );
  }

  bool _isThisQuarterSelected() {
    final now = DateTime.now();
    final qs = ((now.month - 1) ~/ 3) * 3 + 1;
    return _matchesPreset(
      DateTime(now.year, qs, 1),
      DateTime(now.year, qs + 3, 0),
    );
  }

  void _setSort(SortOption option) {
    setState(() {
      _draft = _draft.copyWith(sortOption: option);
    });
  }

  void _resetAll() {
    setState(() {
      _draft = FilterState();
      _customStart = null;
      _customEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasCustomDate = !(_isThisWeekSelected() ||
        _isThisMonthSelected() ||
        _isThisQuarterSelected()) &&
        _hasCustomRange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.filter_alt, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('Filtres & Tri Avancés',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _buildLabel('Période d\'émission'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                label: 'Cette semaine',
                selected: _isThisWeekSelected(),
                onTap: _applyThisWeek,
              ),
              _buildChoiceChip(
                label: DateFormat('MMMM yyyy', 'fr_FR').format(DateTime.now()),
                selected: _isThisMonthSelected(),
                onTap: _applyThisMonth,
              ),
              _buildChoiceChip(
                label: 'Trimestre actuel',
                selected: _isThisQuarterSelected(),
                onTap: _applyThisQuarter,
              ),
              _buildChoiceChip(
                label: 'Personnalisé',
                selected: hasCustomDate,
                icon: Icons.calendar_month,
                onTap: _pickCustomRange,
              ),
            ],
          ),
          if (_customStart != null && _customEnd != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Du ${DateFormat('dd/MM/yyyy').format(_customStart!)} au ${DateFormat('dd/MM/yyyy').format(_customEnd!)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.primary),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildLabel('Trier par'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                label: 'Montant (Décroissant)',
                selected: _draft.sortOption == SortOption.amountDesc,
                onTap: () => _setSort(SortOption.amountDesc),
              ),
              _buildChoiceChip(
                label: 'Montant (Croissant)',
                selected: _draft.sortOption == SortOption.amountAsc,
                onTap: () => _setSort(SortOption.amountAsc),
              ),
              _buildChoiceChip(
                label: 'Date (Plus récent)',
                selected: _draft.sortOption == SortOption.dateDesc,
                onTap: () => _setSort(SortOption.dateDesc),
              ),
              _buildChoiceChip(
                label: 'Date (Plus ancien)',
                selected: _draft.sortOption == SortOption.dateAsc,
                onTap: () => _setSort(SortOption.dateAsc),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _resetAll,
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      widget.onFilterChanged(_draft);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.onPrimary : cs.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}