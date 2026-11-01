import 'package:flutter/material.dart';
import '../../services/nutrition/nutrition_service.dart';
import '../controllers/app_state.dart';

class SavedMealsScreen extends StatefulWidget {
  const SavedMealsScreen({super.key});
  @override
  State<SavedMealsScreen> createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends State<SavedMealsScreen> {
  @override
  Widget build(BuildContext context) {
    final service = NutritionService(ServicesScope.of(context).db);
    return Scaffold(
      appBar: AppBar(title: const Text('Remembered meals')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: service.meals(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load meals.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final meals = snapshot.data!;
            return ListView(padding: const EdgeInsets.all(24), children: [
              const Text('Edit a food entry and turn on “Remember as my meal”. '
                  'Use its name next time, or write “2 servings of my oats”. '
                  'Update a meal by saving the same name again. '
                  'Forgetting a meal keeps your past food entries.'),
              const SizedBox(height: 20),
              if (meals.isEmpty)
                const Text('Your remembered meals will appear here.'),
              for (final meal in meals)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(meal['name'] as String),
                  subtitle: Text(
                      'Per serving · ${(meal['values'] as Map).entries.map((e) => '${(e.value as num).toStringAsFixed(1)} ${e.key == 'calories' ? 'kcal' : 'g ${e.key}'}').join(' · ')}'),
                  trailing: IconButton(
                      tooltip: 'Forget meal',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                    title: Text('Forget ${meal['name']}?'),
                                    content: const Text(
                                        'Past entries will stay in your history.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel')),
                                      FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Forget'))
                                    ]));
                        if (confirmed != true) {
                          return;
                        }
                        try {
                          await service.forget(meal['id'] as String);
                          if (mounted) setState(() {});
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Could not forget this meal. Try again.')));
                          }
                        }
                      }),
                ),
            ]);
          }),
    );
  }
}
