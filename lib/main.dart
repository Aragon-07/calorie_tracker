import 'package:flutter/material.dart';

void main() {
  runApp(const CalorieTrackerApp());
}

/// Model representing a single food entry.
class FoodItem {
  final String id;
  final String name;
  final double calories;
  final DateTime timestamp;

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.timestamp,
  });

  /// Formats calories cleanly without trailing '.0' for whole numbers.
  String get formattedCalories {
    if (calories == calories.roundToDouble()) {
      return '${calories.toInt()} kcal';
    }
    return '${calories.toStringAsFixed(1)} kcal';
  }
}

class CalorieTrackerApp extends StatelessWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
      ),
      home: const CalorieTrackerHomeScreen(),
    );
  }
}

class CalorieTrackerHomeScreen extends StatefulWidget {
  const CalorieTrackerHomeScreen({super.key});

  @override
  State<CalorieTrackerHomeScreen> createState() =>
      _CalorieTrackerHomeScreenState();
}

class _CalorieTrackerHomeScreenState extends State<CalorieTrackerHomeScreen> {
  final List<FoodItem> _foodItems = [];
  double _dailyGoal = 2000;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _nameFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double get _totalCalories =>
      _foodItems.fold(0.0, (sum, item) => item.calories + sum);

  double get _remainingCalories => _dailyGoal - _totalCalories;

  String _formatCalorieValue(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()} kcal';
    }
    return '${value.toStringAsFixed(1)} kcal';
  }

  String _formatTodayDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String? _validateFoodName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a food name';
    }
    return null;
  }

  String? _validateCalorieAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter calorie amount';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  void _submitInlineForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final calories = double.parse(_caloriesController.text.trim());

      setState(() {
        _foodItems.insert(
          0,
          FoodItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: name,
            calories: calories,
            timestamp: DateTime.now(),
          ),
        );
      });

      _nameController.clear();
      _caloriesController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _deleteFoodItem(String id) {
    setState(() {
      _foodItems.removeWhere((item) => item.id == id);
    });
  }

  Future<void> _showEditGoalDialog() async {
    final goalController = TextEditingController(
      text: _dailyGoal.toInt().toString(),
    );
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Daily Calorie Goal'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: goalController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Daily Goal (kcal)',
                border: OutlineInputBorder(),
                suffixText: 'kcal',
              ),
              validator: _validateCalorieAmount,
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  setState(() {
                    _dailyGoal = double.parse(goalController.text.trim());
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save Goal'),
            ),
          ],
        );
      },
    );
    goalController.dispose();
  }

  Future<void> _showAddFoodModal() async {
    final modalNameController = TextEditingController();
    final modalCaloriesController = TextEditingController();
    final modalFormKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Food Item'),
          content: Form(
            key: modalFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: modalNameController,
                  decoration: const InputDecoration(
                    labelText: 'Food Name',
                    hintText: 'e.g., Grilled Chicken Salad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateFoodName,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: modalCaloriesController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Calorie Amount (kcal)',
                    hintText: 'e.g., 350',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_fire_department_outlined),
                    suffixText: 'kcal',
                  ),
                  validator: _validateCalorieAmount,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (modalFormKey.currentState!.validate()) {
                  final name = modalNameController.text.trim();
                  final calories =
                      double.parse(modalCaloriesController.text.trim());
                  setState(() {
                    _foodItems.insert(
                      0,
                      FoodItem(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: name,
                        calories: calories,
                        timestamp: DateTime.now(),
                      ),
                    );
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save Food'),
            ),
          ],
        );
      },
    );
    modalNameController.dispose();
    modalCaloriesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverGoal = _remainingCalories < 0;
    final progress = _dailyGoal > 0
        ? (_totalCalories / _dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calorie Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodModal,
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
        tooltip: 'Quick Add Food',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Today's Date Display Banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Today: ${_formatTodayDate(DateTime.now())}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3 Calorie Summary Cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SummaryCard(
                      key: const Key('total_calories_card'),
                      title: 'Total Calories',
                      value: _formatCalorieValue(_totalCalories),
                      icon: Icons.local_fire_department,
                      accentColor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      key: const Key('daily_goal_card'),
                      title: 'Daily Goal',
                      value: _formatCalorieValue(_dailyGoal),
                      icon: Icons.flag_outlined,
                      accentColor: Colors.blue.shade700,
                      onActionTap: _showEditGoalDialog,
                      actionIcon: Icons.edit_outlined,
                      actionTooltip: 'Edit Daily Goal',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      key: const Key('remaining_calories_card'),
                      title: 'Remaining Calories',
                      value: _formatCalorieValue(_remainingCalories),
                      icon: isOverGoal
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      accentColor: isOverGoal
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                      progress: progress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Add Food Form Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Log a Meal or Snack',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          key: const Key('food_name_field'),
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Food Name',
                            hintText: 'e.g., Oatmeal with Berries',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.restaurant),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: _validateFoodName,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          key: const Key('calorie_amount_field'),
                          controller: _caloriesController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Calorie Amount (kcal)',
                            hintText: 'e.g., 250',
                            border: OutlineInputBorder(),
                            prefixIcon:
                                Icon(Icons.local_fire_department_outlined),
                            suffixText: 'kcal',
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitInlineForm(),
                          validator: _validateCalorieAmount,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          key: const Key('add_food_button'),
                          onPressed: _submitInlineForm,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add Food'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Food List Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Food Log",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_foodItems.length} ${_foodItems.length == 1 ? 'item' : 'items'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Food List (ListView.builder) or Empty State
              if (_foodItems.isEmpty)
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.no_food_outlined,
                          size: 40,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No food items logged today yet.',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter a food name and calorie amount above to start tracking.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _foodItems.length,
                  itemBuilder: (context, index) {
                    final item = _foodItems[index];
                    return Card(
                      key: ValueKey(item.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.fastfood_outlined, size: 20),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          item.formattedCalories,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red.shade600,
                          tooltip: 'Delete ${item.name}',
                          onPressed: () => _deleteFoodItem(item.id),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  final String? actionTooltip;
  final double? progress;

  const _SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onActionTap,
    this.actionIcon,
    this.actionTooltip,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accentColor, size: 20),
                if (onActionTap != null && actionIcon != null)
                  InkWell(
                    onTap: onActionTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Tooltip(
                      message: actionTooltip ?? '',
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          actionIcon,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: accentColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
