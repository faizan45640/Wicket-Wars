import 'innings_result.dart';

/// Passed to [MatchResultScreen] after a Firestore-backed match completes.
class MatchResultArgs {
  const MatchResultArgs({
    required this.youWon,
    required this.innings1,
    required this.innings2,
    required this.headline,
    required this.coinsEarned,
    required this.xpEarned,
  });

  final bool youWon;
  final InningsResult innings1;
  final InningsResult innings2;
  final String headline;
  final int coinsEarned;
  final int xpEarned;
}
