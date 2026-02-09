import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Data classes and enums for managing filter state
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

// The Filter Panel Widget
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

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _searchController = TextEditingController(text: _currentFilters.searchQuery);
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
      if (_searchController.text != _currentFilters.searchQuery) {
        _updateFilters(searchQuery: _searchController.text);
      }
    });
  }

  @override
  void dispose() {
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
    debugPrint('FilterPanel _currentFilters updated: '
        'searchQuery: ${(_currentFilters.searchQuery.isEmpty) ? 'empty' : _currentFilters.searchQuery}, '
        'year: ${_currentFilters.year ?? 'null'}, '
        'month: ${_currentFilters.month ?? 'null'}, '
        'startDate: ${_currentFilters.startDate?.toIso8601String() ?? 'null'}, '
        'endDate: ${_currentFilters.endDate?.toIso8601String() ?? 'null'}, '
        'sortOption: ${_currentFilters.sortOption}');
    widget.onFilterChanged(_currentFilters);
    setState(() {}); // Update the panel's own UI
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _currentFilters.startDate : _currentFilters.endDate) ?? DateTime.now(),
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
    final monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filtres & Tri', style: Theme.of(context).textTheme.headlineSmall),
              TextButton(
                onPressed: () {
                  _searchController.clear();
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
                child: const Text('Réinitialiser'),
              )
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher (Réf, Demandeur, etc.)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _currentFilters.year,
                  decoration: InputDecoration(labelText: 'Année', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Toutes')),
                    ...widget.availableYears.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))),
                  ],
                  onChanged: (value) => _updateFilters(year: value, resetYear: value == null),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _currentFilters.month,
                  decoration: InputDecoration(labelText: 'Mois', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Tous')),
                    ...List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(monthNames[index]))),
                  ],
                  onChanged: (value) => _updateFilters(month: value, resetMonth: value == null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date de début',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    suffixIcon: _startDateController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _startDateController.clear();
                              _updateFilters(startDate: null, resetStartDate: true);
                            },
                          )
                        : null,
                  ),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _endDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date de fin',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    suffixIcon: _endDateController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _endDateController.clear();
                              _updateFilters(endDate: null, resetEndDate: true);
                            },
                          )
                        : null,
                  ),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Trier par', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<SortOption>(
            segments: const [
              ButtonSegment(value: SortOption.dateDesc, label: Text('Date'), icon: Icon(Icons.arrow_downward)),
              ButtonSegment(value: SortOption.dateAsc, label: Text('Date'), icon: Icon(Icons.arrow_upward)),
              ButtonSegment(value: SortOption.amountDesc, label: Text('Montant'), icon: Icon(Icons.arrow_downward)),
              ButtonSegment(value: SortOption.amountAsc, label: Text('Montant'), icon: Icon(Icons.arrow_upward)),
            ],
            selected: {_currentFilters.sortOption},
            onSelectionChanged: (newSelection) {
              _updateFilters(sortOption: newSelection.first);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}