import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srilankani_food_recognition/main.dart';
import 'package:srilankani_food_recognition/utils/constants.dart';

void main() {
  testWidgets('FoodShot loads home with title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.textContaining('Sri Lankan'), findsWidgets);
  });
}
