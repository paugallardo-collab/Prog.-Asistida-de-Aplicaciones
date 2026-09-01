import 'package:calculadora/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('suma dos números', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    for (final key in ['button_7', 'button_+', 'button_5', 'button_=']) {
      await tester.tap(find.byKey(Key(key)));
    }
    await tester.pump();
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('muestra error al dividir entre cero', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    for (final key in ['button_8', 'button_÷', 'button_0', 'button_=']) {
      await tester.tap(find.byKey(Key(key)));
    }
    await tester.pump();
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('No se puede dividir entre cero'), findsOneWidget);
  });
}
