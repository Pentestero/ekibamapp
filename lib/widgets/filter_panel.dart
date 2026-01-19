import 'package:flutter/material.dart';

// Data classes and enums for managing filter state
enum SortOption { dateDesc, dateAsc, amountDesc, amountAsc }

class FilterState {
  final String searchQuery;
  final int? year;
  final int? month;
  final SortOption sortOption;

  FilterState({
    this.searchQuery = '',
    this.year,
    this.month,
    this.sortOption = SortOption.dateDesc,
  });

  FilterState copyWith({
    String? searchQuery,
    int? year,
    int? month,
    SortOption? sortOption,
    bool resetYear = false,
    bool resetMonth = false,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      year: resetYear ? null : year ?? this.year,
      month: resetMonth ? null : month ?? this.month,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

// The Filter Panel Widget
class FilterPanel extends StatefulWidget {
  final FilterState initialFilters;
  final List<int> availableYears;
  final Function(FilterState) onFilterChanged;

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

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _searchController = TextEditingController(text: _currentFilters.searchQuery);

    _searchController.addListener(() {
      if (_searchController.text != _currentFilters.searchQuery) {
        _updateFilters(searchQuery: _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilters({
    String? searchQuery,
    int? year,
    int? month,
    SortOption? sortOption,
    bool resetYear = false,
    bool resetMonth = false,
  }) {
    _currentFilters = _currentFilters.copyWith(
      searchQuery: searchQuery,
      year: year,
      month: month,
      sortOption: sortOption,
      resetYear: resetYear,
      resetMonth: resetMonth,
    );
    widget.onFilterChanged(_currentFilters);
    setState(() {}); // Update the panel's own UI
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
                  _updateFilters(
                    searchQuery: '',
                    resetYear: true,
                    resetMonth: true,
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
                  value: _currentFilters.year,
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
                  value: _currentFilters.month,
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
