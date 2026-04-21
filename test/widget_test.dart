import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wicket_wars/main.dart';

void main() {
  testWidgets('Home dashboard loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('CRICKET SIM MASTER'), findsOneWidget);
    expect(find.text('Player123'), findsOneWidget);
  });
}
