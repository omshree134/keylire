import 'package:flutter/material.dart';

import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';
import '../../services/nutrition/nutrition_service.dart';

/// Returns true if something changed.
Future<bool?> showEditEntrySheet(BuildContext context, EventView e) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final s = ServicesScope.of(context);
  final keys = await s.db.activeKeys();
  if (!context.mounted) return null;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) =>
        _EditBody(e: e, keys: [for (final k in keys) (id: k.id, name: k.name)]),
  );
}

class _EditBody extends StatefulWidget {
  const _EditBody({required this.e, required this.keys});
  final EventView e;
  final List<({int id, String name})> keys;
  @override
  State<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends State<_EditBody> {
  late final _text = TextEditingController(text: widget.e.rawText);
  late final _note = TextEditingController(text: widget.e.note ?? '');
  late final _qty = TextEditingController(
      text: widget.e.quantity == null ? '' : _n(widget.e.quantity!));
  late final _unit = TextEditingController(text: widget.e.unit ?? '');
  late final _dur =
      TextEditingController(text: widget.e.durationMin?.toString() ?? '');
  late int? _keyId = widget.e.keyId;
  late DateTime _at = widget.e.local;
  late List<({int id, String name})> _keys = widget.keys;
  bool _noteOpen = false;
  late final _nutrients = {
    for (final key in NutritionService.nutrients)
      key: TextEditingController(
          text: widget.e.nutritionMetadata[key]?.toString() ?? '')
  };
  late final _servings = TextEditingController(
      text:
          widget.e.nutritionMetadata['nutrition_servings']?.toString() ?? '1');
  late final _mealName = TextEditingController(
      text: widget.e.nutritionMetadata['meal_name']?.toString() ??
          widget.e.rawText);
  final _aliases = TextEditingController();
  bool _remember = false;
  bool _nutritionTouched = false;
  bool _saving = false;
  String? _error;
  late bool _nutritionOpen = widget.e.calories != null ||
      widget.e.protein != null ||
      widget.e.nutritionMetadata['photo_kind'] == 'food' ||
      widget.e.nutritionMetadata['nutrition_needs_review'] == true;
  List<Map<String, dynamic>> _meals = [];
  Map<String, dynamic>? _selectedMeal;

  static String _n(double q) =>
      q == q.roundToDouble() ? '${q.toInt()}' : q.toStringAsFixed(1);

  @override
  void initState() {
    super.initState();
    _noteOpen = (widget.e.note ?? '').isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMeals();
    });
  }

  Future<void> _loadMeals() async {
    final meals = await NutritionService(ServicesScope.of(context).db).meals();
    if (mounted) setState(() => _meals = meals);
  }

  void _useMeal(Map<String, dynamic> meal) {
    final servings = double.tryParse(_servings.text) ?? 1;
    final values = NutritionService.valuesFor(meal, servings);
    setState(() {
      _selectedMeal = meal;
      _mealName.text = meal['name'] as String;
      _aliases.text = (meal['aliases'] as List).join(', ');
      for (final key in NutritionService.nutrients) {
        _nutrients[key]!.text =
            values[key] == null ? '' : _n((values[key] as num).toDouble());
      }
      _nutritionTouched = true;
      _nutritionOpen = true;
    });
  }

  Future<void> _newKey() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('New key'),
        content: TextField(
            controller: c,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'gym, reading, lunch…')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(d, c.text.trim().toLowerCase()),
              child: const Text('Add')),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final s = ServicesScope.of(context);
    final id = await s.db.createKey(name);
    final ks = await s.db.activeKeys();
    setState(() {
      _keys = [for (final k in ks) (id: k.id, name: k.name)];
      _keyId = id;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final t = _text.text.trim();
    if (t.isEmpty) return;
    final totals = <String, double>{};
    final servings = double.tryParse(_servings.text.trim());
    if (_nutritionTouched || _remember) {
      for (final entry in _nutrients.entries) {
        if (entry.value.text.trim().isEmpty) continue;
        final number = double.tryParse(entry.value.text.trim());
        if (number == null ||
            !number.isFinite ||
            number < 0 ||
            number > 100000) {
          setState(
              () => _error = 'Enter valid, non-negative nutrition values.');
          return;
        }
        totals[entry.key] = number;
      }
      if (servings == null ||
          !servings.isFinite ||
          servings <= 0 ||
          (_remember && (_mealName.text.trim().isEmpty || totals.isEmpty))) {
        setState(() => _error =
            'Enter a positive serving count, meal name and nutrition.');
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final s = ServicesScope.of(context);
    try {
      await TodayController(s).updateEvent(
        id: widget.e.id,
        rawText: t,
        keyId: _keyId,
        at: _at,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        durationMin: int.tryParse(_dur.text.trim()),
        quantity: double.tryParse(_qty.text.trim()),
        unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
        nutrition: _nutritionTouched || _remember
            ? {
                ...totals,
                'nutrition_servings': servings,
                'nutrition_needs_review': false,
                if (_remember || _selectedMeal != null)
                  'meal_name': _mealName.text.trim(),
              }
            : null,
        rememberMealName: _remember ? _mealName.text.trim() : null,
        mealAliases: _aliases.text.split(','),
        mealServings: servings ?? 1,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    final hh = _at.hour.toString().padLeft(2, '0');
    final mm = _at.minute.toString().padLeft(2, '0');

    return Padding(
      padding: EdgeInsets.fromLTRB(
          dl.x5, dl.x4, dl.x5, MediaQuery.viewInsetsOf(context).bottom + dl.x5),
      child: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                InkWell(
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_at));
                    if (t != null) {
                      setState(() => _at = DateTime(
                          _at.year, _at.month, _at.day, t.hour, t.minute));
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text('$hh:$mm',
                        style: DlType.mono(context,
                            size: 15,
                            color: arcColorFor(_at),
                            weight: FontWeight.w600)),
                  ),
                ),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context, false)),
              ]),
              TextField(
                controller: _text,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(hintText: 'What happened'),
              ),
              SizedBox(height: dl.x4),
              Wrap(spacing: dl.x2, runSpacing: dl.x2, children: [
                for (final k in _keys)
                  ChoiceChip(
                      label: Text(k.name),
                      selected: _keyId == k.id,
                      onSelected: (v) =>
                          setState(() => _keyId = v ? k.id : null)),
                ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('New key'),
                    onPressed: _newKey),
              ]),
              SizedBox(height: dl.x4),
              Row(children: [
                SizedBox(
                    width: 72,
                    child: TextField(
                        controller: _qty,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: DlType.mono(context,
                            size: 15, color: theme.colorScheme.onSurface),
                        decoration: const InputDecoration(hintText: '0'))),
                SizedBox(width: dl.x2),
                SizedBox(
                    width: 80,
                    child: TextField(
                        controller: _unit,
                        decoration:
                            const InputDecoration(hintText: 'km, pages…'))),
                SizedBox(width: dl.x4),
                SizedBox(
                    width: 60,
                    child: TextField(
                        controller: _dur,
                        keyboardType: TextInputType.number,
                        style: DlType.mono(context,
                            size: 15, color: theme.colorScheme.onSurface),
                        decoration: const InputDecoration(hintText: 'min'))),
                SizedBox(width: dl.x2),
                Text('min', style: theme.textTheme.bodySmall),
              ]),
              SizedBox(height: dl.x3),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _nutritionOpen = !_nutritionOpen),
                icon: const Icon(Icons.restaurant_outlined, size: 18),
                label: Text(_nutritionOpen
                    ? 'Nutrition for this entry'
                    : 'Add nutrition'),
              ),
              if (_nutritionOpen) ...[
                Text(
                    'Values below are totals for the portion you ate. Blank means unknown.',
                    style: theme.textTheme.bodySmall),
                for (final meal in _meals.where((m) =>
                    m['id'] == widget.e.nutritionMetadata['meal_suggestion']))
                  OutlinedButton(
                      onPressed: () => _useMeal(meal),
                      child: Text(
                          'Looks similar to ${meal['name']} — use and check portion')),
                if (_meals.isNotEmpty)
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Use a saved meal'),
                    items: [
                      for (final meal in _meals)
                        DropdownMenuItem(
                            value: meal['id'] as String,
                            child: Text(meal['name'] as String))
                    ],
                    onChanged: (id) =>
                        _useMeal(_meals.firstWhere((m) => m['id'] == id)),
                  ),
                TextField(
                    controller: _servings,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Servings eaten',
                        helperText:
                            'Saved meals use one serving as their base.'),
                    onChanged: (_) {
                      _nutritionTouched = true;
                      if (_selectedMeal != null) _useMeal(_selectedMeal!);
                    }),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  for (final entry in _nutrients.entries)
                    SizedBox(
                        width: 135,
                        child: TextField(
                          controller: entry.value,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: switch (entry.key) {
                            'calories' => 'Calories (kcal)',
                            'protein' => 'Protein (g)',
                            'carbs' => 'Carbs (g)',
                            _ => 'Fat (g)',
                          }),
                          onChanged: (_) {
                            _nutritionTouched = true;
                            _selectedMeal = null;
                          },
                        )),
                ]),
                SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remember as my meal'),
                    subtitle: const Text(
                        'Reuse these values by name. Photos always need portion confirmation.'),
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v)),
                if (_remember) ...[
                  TextField(
                      controller: _mealName,
                      decoration: const InputDecoration(
                          labelText: 'Meal name',
                          hintText: 'My breakfast oats')),
                  TextField(
                      controller: _aliases,
                      decoration: const InputDecoration(
                          labelText: 'Other names, separated by commas',
                          hintText: 'usual oats, morning oats')),
                  Text('Saving an existing name replaces its saved nutrition.',
                      style: theme.textTheme.bodySmall),
                ],
              ],
              if (!_noteOpen)
                TextButton.icon(
                    onPressed: () => setState(() => _noteOpen = true),
                    icon: const Icon(Icons.notes, size: 18),
                    label: const Text('Add a note'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero))
              else
                TextField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 2000,
                  buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      null,
                  decoration: const InputDecoration(hintText: 'Note'),
                ),
              SizedBox(height: dl.x5),
              Row(children: [
                const Spacer(),
                FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save')),
              ]),
              if (_error != null)
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ]),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _text,
      _note,
      _qty,
      _unit,
      _dur,
      _servings,
      _mealName,
      _aliases,
      ..._nutrients.values
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
