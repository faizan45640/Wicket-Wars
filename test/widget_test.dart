import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wicket_wars/data/placeholder/placeholder_leaderboard_repository.dart';
import 'package:wicket_wars/data/placeholder/placeholder_match_history_repository.dart';
import 'package:wicket_wars/data/placeholder/placeholder_match_repository.dart';
import 'package:wicket_wars/data/placeholder/placeholder_squad_repository.dart';
import 'package:wicket_wars/data/placeholder/placeholder_user_repository.dart';
import 'package:wicket_wars/data/providers.dart';
import 'package:wicket_wars/firebase_options.dart';
import 'package:wicket_wars/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  });

  testWidgets('Login screen shows when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWith((ref) => PlaceholderUserRepository()),
          squadRepositoryProvider.overrideWith((ref) => PlaceholderSquadRepository()),
          matchRepositoryProvider.overrideWith((ref) => PlaceholderMatchRepository()),
          leaderboardRepositoryProvider
              .overrideWith((ref) => PlaceholderLeaderboardRepository()),
          matchHistoryRepositoryProvider
              .overrideWith((ref) => PlaceholderMatchHistoryRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WICKET WARS'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
  });
}
