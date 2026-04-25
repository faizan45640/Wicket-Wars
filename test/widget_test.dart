import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wicket_wars/auth/demo_credentials.dart';
import 'package:wicket_wars/main.dart';

void main() {
  testWidgets('Home dashboard loads after login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('WICKET WARS'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('login_email')), kDemoEmail);
    await tester.enterText(
      find.byKey(const Key('login_password')),
      kDemoPassword,
    );
    await tester.tap(find.text('LOG IN'));
    await tester.pumpAndSettle();

    expect(find.textContaining('CRICKET SIM MASTER'), findsOneWidget);
    expect(find.text('Player123'), findsOneWidget);
  });
}
