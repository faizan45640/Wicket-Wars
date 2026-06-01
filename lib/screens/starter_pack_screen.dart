import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/cricket_player.dart';
import '../data/models/player_tier.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/player_card_image.dart';

class StarterPackScreen extends ConsumerStatefulWidget {
  const StarterPackScreen({super.key});

  @override
  ConsumerState<StarterPackScreen> createState() => _StarterPackScreenState();
}

class _StarterPackScreenState extends ConsumerState<StarterPackScreen> {
  var _opening = false;
  List<CricketPlayer> _players = const [];
  String? _generationSource;
  var _alreadyOpened = false;
  String? _error;

  Future<void> _openPack() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || _opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final opening = await ref
          .read(squadRepositoryProvider)
          .openStarterPack(uid: uid);
      if (!mounted) return;
      setState(() {
        _players = opening.players;
        _generationSource = opening.generationSource;
        _alreadyOpened = opening.alreadyOpened;
      });
      ref.invalidate(userProfileProvider);
      ref.invalidate(squadProvider(uid));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium =
        _players.where((p) => p.playerTier == PlayerTier.premium).firstOrNull;
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        title: const Text(
          'STARTER PACK',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_players.isEmpty) ...[
              const SizedBox(height: 28),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: GameColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GameColors.neon, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: GameColors.neon,
                    size: 92,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Open your first squad pack',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '15 cards: 1 premium real-player pull and 14 generated starter players.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.95),
                  height: 1.35,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade200),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _opening ? null : _openPack,
                style: FilledButton.styleFrom(
                  backgroundColor: GameColors.neon,
                  foregroundColor: GameColors.onNeonButton,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child:
                    _opening
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GameColors.onNeonButton,
                          ),
                        )
                        : const Text(
                          'OPEN PACK',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
              ),
            ] else ...[
              if (premium != null) _PremiumReveal(player: premium),
              const SizedBox(height: 18),
              _GenerationStatus(
                source: _generationSource,
                alreadyOpened: _alreadyOpened,
              ),
              const SizedBox(height: 12),
              Text(
                '${_players.length} players added to your squad',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _players.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) {
                  return _PackCard(player: _players[index]);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/squad'),
                style: FilledButton.styleFrom(
                  backgroundColor: GameColors.neon,
                  foregroundColor: GameColors.onNeonButton,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'VIEW SQUAD',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GenerationStatus extends StatelessWidget {
  const _GenerationStatus({required this.source, required this.alreadyOpened});

  final String? source;
  final bool alreadyOpened;

  @override
  Widget build(BuildContext context) {
    final fallback = source == 'fallback';
    final existing = alreadyOpened || source == 'alreadyOpened';
    final missing = source == null || source == 'unknown';
    final usedAi = !fallback && !existing && !missing;
    final label =
        usedAi
            ? 'Basic players generated by Google AI (${source!})'
            : fallback
            ? 'Fallback starter players used'
            : existing
            ? 'Starter pack was already opened; showing saved squad cards'
            : 'Generation source missing. Deploy latest openStarterPack function.';
    final accent =
        usedAi
            ? GameColors.neon
            : fallback
            ? Colors.amber
            : existing
            ? Colors.cyanAccent
            : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent),
      ),
      child: Row(
        children: [
          Icon(
            usedAi
                ? Icons.auto_awesome_rounded
                : existing
                ? Icons.inventory_2_outlined
                : Icons.offline_bolt_outlined,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumReveal extends StatelessWidget {
  const _PremiumReveal({required this.player});

  final CricketPlayer player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: PlayerCardImage(
              imageAsset: player.cardImageAsset,
              imageUrl: player.avatarUrl,
              isReal: player.isRealPlayer,
              playerName: player.displayName,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREMIUM PULL',
                  style: TextStyle(
                    color: Colors.amber.shade400,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  player.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${player.roleLabel} · ${player.countryLabel} · OVR ${player.attributes.overall}',
                  style: TextStyle(color: GameColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.player});

  final CricketPlayer player;

  @override
  Widget build(BuildContext context) {
    final premium = player.playerTier == PlayerTier.premium;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: premium ? Colors.amber.shade400 : GameColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: PlayerCardImage(
              imageAsset: player.cardImageAsset,
              imageUrl: player.avatarUrl,
              isReal: player.isRealPlayer,
              playerName: player.displayName,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            player.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${player.effectiveRole.shortLabel} ${player.attributes.overall}',
            style: TextStyle(
              color: premium ? Colors.amber.shade400 : GameColors.neon,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
