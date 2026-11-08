import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calorie_tracker/main.dart';

void main() {
  testWidgets('Calorie Tracker adds, validates, and deletes food items',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CalorieTrackerApp());

    // Verify AppBar title and initial summary card values
    expect(find.text('Calorie Tracker'), findsOneWidget);
    expect(find.text('Total Calories'), findsOneWidget);
    expect(find.text('Daily Goal'), findsOneWidget);
    expect(find.text('Remaining Calories'), findsOneWidget);
    expect(find.text('0 kcal'), findsOneWidget);
    expect(find.text('2000 kcal'), findsNWidgets(2)); // Daily Goal & Remaining

    // Verify empty state is shown initially
    expect(find.text('No food items logged today yet.'), findsOneWidget);

    // 1. Test Validation: submit empty form
    final addButton = find.byKey(const Key('add_food_button'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump();

    expect(find.text('Please enter a food name'), findsOneWidget);
    expect(find.text('Please enter calorie amount'), findsOneWidget);

    // Test invalid calorie number
    final nameField = find.byKey(const Key('food_name_field'));
    final caloriesField = find.byKey(const Key('calorie_amount_field'));

    await tester.enterText(nameField, 'Apple');
    await tester.enterText(caloriesField, '-50');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump();

    expect(find.text('Enter a valid positive number'), findsOneWidget);

    // 2. Test Adding a Valid Food Item
    await tester.enterText(nameField, 'Grilled Chicken Salad');
    await tester.enterText(caloriesField, '450');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump();

    // Verify food item appears in ListView and summaries update
    expect(find.text('Grilled Chicken Salad'), findsOneWidget);
    expect(find.text('450 kcal'), findsNWidgets(2)); // Total Card + List Tile
    expect(find.text('1550 kcal'), findsOneWidget); // Remaining (2000 - 450)

    // 3. Test Deleting the Food Item
    final deleteButton = find.byIcon(Icons.delete_outline);
    expect(deleteButton, findsOneWidget);
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pump();

    // Verify food item is removed and summaries reset
    expect(find.text('Grilled Chicken Salad'), findsNothing);
    expect(find.text('0 kcal'), findsOneWidget);
    expect(find.text('2000 kcal'), findsNWidgets(2));
  });
}
