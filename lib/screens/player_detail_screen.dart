import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/cricket_player.dart';
import '../data/models/player_attributes.dart';
import '../data/models/training_state.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

// Hardcoded economy / training (replace with backend later).
const Duration kTrainingDuration = Duration(seconds: 45);
const int kInitialCoins = 1500;
const int kUpgradeCoinCost = 100;
const int kUpgradeStatBoost = 2;
const int kTrainingStatGain = 1;

/// Full-screen player view: summary, scrollable stats, train (timed), upgrade (coins).
class PlayerDetailScreen extends StatefulWidget {
  const PlayerDetailScreen({super.key, required this.player});

  final CricketPlayer player;

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  late CricketPlayer _player;
  int _coins = kInitialCoins;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    if (_player.isTraining) {
      _armTrainingTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _armTrainingTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_player.training == null) {
        _ticker?.cancel();
        return;
      }
      if (_player.training!.isComplete) {
        _onTrainingComplete();
      } else {
        setState(() {});
      }
    });
  }

  void _onTrainingComplete() {
    _ticker?.cancel();
    _ticker = null;
    final a = _player.attributes;
    if (!mounted) return;
    setState(() {
      _player = _player.copyWith(
        clearTraining: true,
        attributes: a.copyWith(
          batting: a.batting + kTrainingStatGain,
          bowling: a.bowling + kTrainingStatGain,
          fielding: a.fielding + kTrainingStatGain,
          stamina: a.stamina + kTrainingStatGain,
          consistency: a.consistency + kTrainingStatGain,
        ),
      );
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Training complete — all attributes +$kTrainingStatGain'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startTraining() {
    if (_player.isTraining) return;
    final now = DateTime.now();
    setState(() {
      _player = _player.copyWith(
        training: TrainingState(
          startedAt: now,
          completesAt: now.add(kTrainingDuration),
        ),
      );
    });
    _armTrainingTicker();
  }

  void _upgradeInstant() {
    if (_coins < kUpgradeCoinCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough coins (need $kUpgradeCoinCost)'),
          backgroundColor: GameColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final a = _player.attributes;
    final boosted = _boostWeakest(a, kUpgradeStatBoost);
    setState(() {
      _coins -= kUpgradeCoinCost;
      _player = _player.copyWith(attributes: boosted);
    });
  }

  static PlayerAttributes _boostWeakest(PlayerAttributes a, int by) {
    var bat = a.batting;
    var bwl = a.bowling;
    var fld = a.fielding;
    var sta = a.stamina;
    var con = a.consistency;
    if (bat <= bwl && bat <= fld && bat <= sta && bat <= con) {
      return a.copyWith(batting: bat + by);
    }
    if (bwl <= fld && bwl <= sta && bwl <= con) {
      return a.copyWith(bowling: bwl + by);
    }
    if (fld <= sta && fld <= con) {
      return a.copyWith(fielding: fld + by);
    }
    if (sta <= con) {
      return a.copyWith(stamina: sta + by);
    }
    return a.copyWith(consistency: con + by);
  }

  String get _nameInitial {
    final n = _player.displayName.trim();
    if (n.isEmpty) return '?';
    return n[0].toUpperCase();
  }

  String _trainCountdown() {
    final t = _player.training;
    if (t == null) return '';
    var left = t.completesAt.difference(DateTime.now());
    if (left.isNegative) left = Duration.zero;
    final m = left.inMinutes.remainder(60);
    final s = left.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final a = _player.attributes;
    final ovr = a.overall;
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GameColors.neon, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          _player.displayName.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline, color: GameColors.neon),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _SummaryCard(
              name: _player.displayName,
              ovr: ovr,
              initial: _nameInitial,
              cardImageAsset: _player.cardImageAsset,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Coins: $_coins',
                  style: TextStyle(
                    color: GameColors.muted.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Upgrade: $kUpgradeCoinCost c',
                  style: TextStyle(
                    color: GameColors.muted.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: GameColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: GameColors.cardBorder),
                ),
                elevation: 0,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    const _ScrollHintArrows(),
                    const SizedBox(height: 4),
                    _AttributeBar(label: 'BATTING', value: a.batting, color: const Color(0xFF64B5F6)),
                    const SizedBox(height: 10),
                    _AttributeBar(label: 'BOWLING', value: a.bowling, color: const Color(0xFFFFB74D)),
                    const SizedBox(height: 10),
                    _AttributeBar(label: 'FIELDING', value: a.fielding, color: const Color(0xFF81C784)),
                    const SizedBox(height: 10),
                    _AttributeBar(label: 'STAMINA', value: a.stamina, color: const Color(0xFFBA68C8)),
                    const SizedBox(height: 10),
                    _AttributeBar(
                      label: 'CONSISTENCY',
                      value: a.consistency,
                      color: const Color(0xFF4DD0E1),
                    ),
                    const SizedBox(height: 8),
                    const _ScrollHintArrows(down: true),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _player.isTraining ? null : _startTraining,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4A2E),
                    foregroundColor: const Color(0xFFE0E0E0),
                    disabledBackgroundColor: const Color(0xFF1E1E1E),
                    disabledForegroundColor: GameColors.muted,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: GameColors.neon.withValues(alpha: 0.4)),
                    ),
                  ),
                  icon: Icon(
                    Icons.fitness_center_rounded,
                    color: _player.isTraining ? GameColors.muted : GameColors.neon,
                    size: 22,
                  ),
                  label: Text(
                    _player.isTraining
                        ? 'TRAINING… ${_trainCountdown()}'
                        : 'TRAIN PLAYER  (${kTrainingDuration.inSeconds}s)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _upgradeInstant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.neon,
                    foregroundColor: GameColors.onNeonButton,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.trending_up_rounded, size: 24),
                  label: const Text(
                    'UPGRADE +',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 1),
    );
  }
}

class _ScrollHintArrows extends StatelessWidget {
  const _ScrollHintArrows({this.down = false});

  final bool down;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        down ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
        size: 18,
        color: GameColors.muted.withValues(alpha: 0.45),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.name,
    required this.ovr,
    required this.initial,
    this.cardImageAsset,
  });

  final String name;
  final int ovr;
  final String initial;
  final String? cardImageAsset;

  @override
  Widget build(BuildContext context) {
    final path = cardImageAsset?.trim() ?? '';
    return Card(
      color: GameColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: GameColors.cardBorder),
      ),
      elevation: 0,
      shadowColor: GameColors.neon.withValues(alpha: 0.06),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: GameColors.neon.withValues(alpha: 0.6), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: path.isNotEmpty
                ? Image.asset(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _LetterAvatar(initial: initial),
                  )
                : _LetterAvatar(initial: initial),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF0F0F0),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _OvrStarburst(ovr: ovr),
        ],
      ),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E0E0E),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: GameColors.neon,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _OvrStarburst extends StatelessWidget {
  const _OvrStarburst({required this.ovr});

  final int ovr;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: GameColors.neon.withValues(alpha: 0.12),
                  border: Border.all(
                    color: GameColors.neon.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(4),
                    topRight: const Radius.circular(12),
                    bottomLeft: const Radius.circular(14),
                    bottomRight: const Radius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.08,
            child: Icon(
              Icons.brightness_5_rounded,
              size: 50,
              color: GameColors.neon.withValues(alpha: 0.25),
            ),
          ),
          Text(
            '$ovr',
            style: const TextStyle(
              color: GameColors.neon,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributeBar extends StatelessWidget {
  const _AttributeBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = (value / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: GameColors.muted.withValues(alpha: 0.95),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 8,
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$value',
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Route helper: [extra] should be the [CricketPlayer].
class PlayerDetailRoute {
  static CricketPlayer? playerFromState(GoRouterState state) {
    final extra = state.extra;
    if (extra is CricketPlayer) {
      return extra;
    }
    return null;
  }
}
