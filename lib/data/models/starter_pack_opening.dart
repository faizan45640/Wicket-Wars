import 'cricket_player.dart';

class StarterPackOpening {
  const StarterPackOpening({
    required this.players,
    required this.generationSource,
    required this.alreadyOpened,
  });

  final List<CricketPlayer> players;
  final String generationSource;
  final bool alreadyOpened;

  bool get usedAi =>
      generationSource != 'fallback' &&
      generationSource != 'alreadyOpened' &&
      generationSource != 'unknown';
}
