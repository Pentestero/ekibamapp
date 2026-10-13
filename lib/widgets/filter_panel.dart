import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum SortOption { dateDesc, dateAsc, amountDesc, amountAsc }

class FilterState {
  final String searchQuery;
  final int? year;
  final int? month;
  final DateTime? startDate;
  final DateTime? endDate;
  final SortOption sortOption;

  FilterState({
    this.searchQuery = '',
    this.year,
    this.month,
    this.startDate,
    this.endDate,
    this.sortOption = SortOption.dateDesc,
  });

  FilterState copyWith({
    String? searchQuery,
    int? year,
    int? month,
    DateTime? startDate,
    DateTime? endDate,
    SortOption? sortOption,
    bool resetYear = false,
    bool resetMonth = false,
    bool resetStartDate = false,
    bool resetEndDate = false,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      year: resetYear ? null : year ?? this.year,
      month: resetMonth ? null : month ?? this.month,
      startDate: resetStartDate ? null : startDate ?? this.startDate,
      endDate: resetEndDate ? null : endDate ?? this.endDate,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class FilterPanel extends StatefulWidget {
  final FilterState initialFilters;
  final List<int> availableYears;
  final void Function(FilterState newFilters) onFilterChanged;

  const FilterPanel({
    super.key,
    required this.initialFilters,
    required this.availableYears,
    required this.onFilterChanged,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late FilterState _currentFilters;
  late final TextEditingController _searchController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _searchController =
        TextEditingController(text: _currentFilters.searchQuery);
    _startDateController = TextEditingController(
      text: _currentFilters.startDate != null
          ? DateFormat('dd/MM/yyyy').format(_currentFilters.startDate!)
          : '',
    );
    _endDateController = TextEditingController(
      text: _currentFilters.endDate != null
          ? DateFormat('dd/MM/yyyy').format(_currentFilters.endDate!)
          : '',
    );

    _searchController.addListener(() {
      _searchDebounce?.cancel();
      final query = _searchController.text.trim();
      if (query == _currentFilters.searchQuery) return;
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted && query != _currentFilters.searchQuery) {
          _updateFilters(searchQuery: query);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _updateFilters({
    String? searchQuery,
    int? year,
    int? month,
    DateTime? startDate,
    DateTime? endDate,
    SortOption? sortOption,
    bool resetYear = false,
    bool resetMonth = false,
    bool resetStartDate = false,
    bool resetEndDate = false,
  }) {
    _currentFilters = _currentFilters.copyWith(
      searchQuery: searchQuery,
      year: year,
      month: month,
      startDate: startDate,
      endDate: endDate,
      sortOption: sortOption,
      resetYear: resetYear,
      resetMonth: resetMonth,
      resetStartDate: resetStartDate,
      resetEndDate: resetEndDate,
    );
    debugPrint(
        'FilterPanel _currentFilters updated: searchQuery: ${(_currentFilters.searchQuery.isEmpty) ? 'empty' : _currentFilters.searchQuery}, year: ${_currentFilters.year ?? 'null'}, month: ${_currentFilters.month ?? 'null'}, startDate: ${_currentFilters.startDate?.toIso8601String() ?? 'null'}, endDate: ${_currentFilters.endDate?.toIso8601String() ?? 'null'}, sortOption: ${_currentFilters.sortOption}');
    setState(() {});
  }

  void _applyFilters() {
    widget.onFilterChanged(_currentFilters);
    Navigator.of(context).maybePop();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
        initialDate:
          (isStartDate ? _currentFilters.startDate : _currentFilters.endDate) ??
            DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isStartDate) {
        _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        _updateFilters(startDate: picked);
      } else {
        _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        _updateFilters(endDate: picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactLayout = screenWidth < 420;
    final monthNames = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filtres & Tri',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _searchDebounce?.cancel();
                  _startDateController.clear();
                  _endDateController.clear();
                  _updateFilters(
                    searchQuery: '',
                    resetYear: true,
                    resetMonth: true,
                    resetStartDate: true,
                    resetEndDate: true,
                    sortOption: SortOption.dateDesc,
                  );
                },
                child: Text(compactLayout ? 'Effacer' : 'Réinitialiser'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Recherche',
              helperText: 'Réf. DA, demandeur ou client',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          _buildDateFilters(monthNames, context),
          const SizedBox(height: 24),
          Text('Trier par',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip(
                label: compactLayout ? 'Date' : 'Date récente',
                option: SortOption.dateDesc,
                icon: Icons.arrow_downward,
              ),
              _buildSortChip(
                label: compactLayout ? 'Date' : 'Date ancienne',
                option: SortOption.dateAsc,
                icon: Icons.arrow_upward,
              ),
              _buildSortChip(
                label: compactLayout ? 'Montant' : 'Montant élevé',
                option: SortOption.amountDesc,
                icon: Icons.arrow_downward,
              ),
              _buildSortChip(
                label: compactLayout ? 'Montant' : 'Montant faible',
                option: SortOption.amountAsc,
                icon: Icons.arrow_upward,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _searchDebounce?.cancel();
                    _startDateController.clear();
                    _endDateController.clear();
                    setState(() {
                      _currentFilters = FilterState();
                    });
                  },
                  child: Text(compactLayout ? 'Effacer' : 'Réinitialiser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.check),
                  label: const Text('OK'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilters(List<String> monthNames, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _currentFilters.year,
                decoration: const InputDecoration(labelText: 'Année'),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Toutes')),
                  ...widget.availableYears.map((y) =>
                      DropdownMenuItem(value: y, child: Text(y.toString()))),
                ],
                onChanged: (value) =>
                    _updateFilters(year: value, resetYear: value == null),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _currentFilters.month,
                decoration: const InputDecoration(labelText: 'Mois'),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Tous')),
                  ...List.generate(
                      12,
                      (index) => DropdownMenuItem(
                          value: index + 1, child: Text(monthNames[index]))),
                ],
                onChanged: (value) =>
                    _updateFilters(month: value, resetMonth: value == null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 400) {
              return Column(
                children: [
                  _buildDateInput(context, isStartDate: true),
                  const SizedBox(height: 12),
                  _buildDateInput(context, isStartDate: false),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: _buildDateInput(context, isStartDate: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildDateInput(context, isStartDate: false)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateInput(BuildContext context, {required bool isStartDate}) {
    final controller = isStartDate ? _startDateController : _endDateController;
    final label = isStartDate ? 'Date de début' : 'Date de fin';
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  _updateFilters(
                    startDate: isStartDate ? null : _currentFilters.startDate,
                    endDate: isStartDate ? _currentFilters.endDate : null,
                    resetStartDate: isStartDate,
                    resetEndDate: !isStartDate,
                  );
                },
              )
            : null,
      ),
      onTap: () => _selectDate(context, isStartDate),
    );
  }

  Widget _buildSortChip({
    required String label,
    required SortOption option,
    required IconData icon,
  }) {
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: _currentFilters.sortOption == option,
      onSelected: (_) => _updateFilters(sortOption: option),
    );
  }
}
