import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/time/day_resolver.dart';
import '../../data/db/database.dart' as db;
import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';
import '../widgets/edit_entry_sheet.dart';

/// Full-text search across entries, notes, and keys.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialKeyId});

  final int? initialKeyId;

  static Route<void> route({int? initialKeyId}) => MaterialPageRoute<void>(
        builder: (_) => SearchScreen(initialKeyId: initialKeyId),
      );

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  List<db.Key> _availableKeys = const [];
  Map<int, String> _keyNames = const {};
  int? _selectedKeyId;
  String? _selectedDateRange; // 'all', '7d', '30d', '90d'

  List<db.Event> _results = const [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _selectedKeyId = widget.initialKeyId;
    _searchController.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKeysAndSearch();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadKeysAndSearch() async {
    final services = ServicesScope.of(context);
    final keys = await services.db.activeKeys();
    keys.sort((a, b) => a.name.compareTo(b.name));
    if (!mounted) return;
    setState(() {
      _availableKeys = keys;
      _keyNames = {for (final k in keys) k.id: k.name};
    });
    _executeSearch();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _executeSearch();
    });
  }

  Future<void> _executeSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedKeyId == null && _selectedDateRange == null) {
      if (mounted) {
        setState(() {
          _results = const [];
          _isLoading = false;
          _hasSearched = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final services = ServicesScope.of(context);
    String? fromDate;
    if (_selectedDateRange == '7d') {
      fromDate = DayResolver.formatDay(
          DateTime.now().subtract(const Duration(days: 7)));
    } else if (_selectedDateRange == '30d') {
      fromDate = DayResolver.formatDay(
          DateTime.now().subtract(const Duration(days: 30)));
    } else if (_selectedDateRange == '90d') {
      fromDate = DayResolver.formatDay(
          DateTime.now().subtract(const Duration(days: 90)));
    }

    // Typing a key's name is a key filter, not a text search.
    int? effectiveKey = _selectedKeyId;
    String? effectiveQuery = query.isEmpty ? null : query;
    if (effectiveKey == null && query.isNotEmpty) {
      final hit = _availableKeys
          .where((k) => k.name.toLowerCase() == query.toLowerCase())
          .firstOrNull;
      if (hit != null) {
        effectiveKey = hit.id;
        effectiveQuery = null;
      }
    }

    try {
      final rows = await services.db.searchEvents(
        query: effectiveQuery,
        keyId: effectiveKey,
        fromDate: fromDate,
        limit: 150,
      );
      if (!mounted) return;
      setState(() {
        _results = rows;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedKeyId = null;
      _selectedDateRange = null;
    });
    _executeSearch();
  }

  Future<void> _editEvent(db.Event event) async {
    final eventView = EventView.from(event, _keyNames);
    final changed = await showEditEntrySheet(context, eventView);
    if (changed == true && mounted) {
      _executeSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    final soft = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: theme.textTheme.bodyLarge,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search logs, notes, or tags…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty ||
                    _selectedKeyId != null ||
                    _selectedDateRange != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _clearSearch,
                    tooltip: 'Clear search',
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: dl.x5, vertical: dl.x2),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected:
                      _selectedKeyId == null && _selectedDateRange == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedKeyId = null;
                      _selectedDateRange = null;
                    });
                    _executeSearch();
                  },
                ),
                SizedBox(width: dl.x2),
                // Date range filters
                FilterChip(
                  label: const Text('Past 7 days'),
                  selected: _selectedDateRange == '7d',
                  onSelected: (selected) {
                    setState(() {
                      _selectedDateRange = selected ? '7d' : null;
                    });
                    _executeSearch();
                  },
                ),
                SizedBox(width: dl.x2),
                FilterChip(
                  label: const Text('Past 30 days'),
                  selected: _selectedDateRange == '30d',
                  onSelected: (selected) {
                    setState(() {
                      _selectedDateRange = selected ? '30d' : null;
                    });
                    _executeSearch();
                  },
                ),
                SizedBox(width: dl.x3),
                Container(
                  width: 1,
                  height: 20,
                  color: theme.colorScheme.outline,
                ),
                SizedBox(width: dl.x3),
                // Key filters
                for (final k in _availableKeys) ...[
                  FilterChip(
                    label: Text(k.name),
                    selected: _selectedKeyId == k.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedKeyId = selected ? k.id : null;
                      });
                      _executeSearch();
                    },
                  ),
                  SizedBox(width: dl.x2),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Results section
          Expanded(
            child: _buildBody(theme, dl, soft),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, Dl dl, Color soft) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (!_hasSearched && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(dl.x8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 40, color: soft.withValues(alpha: 0.5)),
              SizedBox(height: dl.x3),
              Text(
                'Search entries by keyword, note, or tag.',
                style: theme.textTheme.bodyMedium?.copyWith(color: soft),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(dl.x8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_outlined,
                  size: 40, color: soft.withValues(alpha: 0.5)),
              SizedBox(height: dl.x3),
              Text(
                'No matching entries found.',
                style: theme.textTheme.bodyMedium?.copyWith(color: soft),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: dl.x5, vertical: dl.x3),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _results[index];
        final localTime = item.tsUtc.toLocal();
        final hh = localTime.hour.toString().padLeft(2, '0');
        final mm = localTime.minute.toString().padLeft(2, '0');
        final keyName = item.keyId != null ? _keyNames[item.keyId] : null;
        final hue = arcColorFor(localTime);

        final parts = <String>[];
        if (item.durationMin != null) {
          parts.add('${item.durationMin} min');
        }
        if (item.quantity != null) {
          final q = item.quantity!;
          final qStr = q == q.roundToDouble()
              ? '${q.toInt()}'
              : q.toStringAsFixed(1);
          parts.add('$qStr ${item.unit ?? ''}'.trim());
        }

        return InkWell(
          onTap: () => _editEvent(item),
          borderRadius: BorderRadius.circular(Dl.radiusSmall),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: dl.x3, horizontal: dl.x1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Time
                SizedBox(
                  width: 74,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.dayDate,
                        style: DlType.mono(context, size: 11, color: soft),
                      ),
                      Text(
                        '$hh:$mm',
                        style: DlType.mono(context,
                            size: 13,
                            color: hue,
                            weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: dl.x2),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.rawText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: soft,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (keyName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: hue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                keyName,
                                style: DlType.mono(context,
                                    size: 10.5,
                                    color: hue,
                                    weight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (parts.isNotEmpty)
                            Text(
                              parts.join(' · '),
                              style: DlType.mono(context,
                                  size: 11, color: soft),
                            ),
                          if (item.status == 'planned') ...[
                            const SizedBox(width: 6),
                            Text(
                              'planned',
                              style: DlType.mono(context,
                                  size: 10.5,
                                  color: theme.colorScheme.outline),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: soft),
              ],
            ),
          ),
        );
      },
    );
  }
}
