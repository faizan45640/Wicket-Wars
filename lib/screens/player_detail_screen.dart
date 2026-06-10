import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models/cricket_player.dart';
import '../data/models/user_profile.dart';
import '../data/providers.dart';
import '../data/training_rules.dart';
import '../services/local_notification_service.dart';
import '../services/rewarded_ad_helper.dart';
import '../services/training_reminder_store.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';
import '../widgets/player_card_image.dart';

/// Full-screen player view: summary, per-attribute training (energy + coins +
/// risk, capped by the player's potential). Coins/energy and player updates
/// persist to Firestore via [userRepositoryProvider] / [squadRepositoryProvider].
class PlayerDetailScreen extends ConsumerStatefulWidget {
  const PlayerDetailScreen({super.key, required this.player});

  final CricketPlayer player;

  @override
  ConsumerState<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends ConsumerState<PlayerDetailScreen> {
  static final NumberFormat _coinFmt = NumberFormat.decimalPattern('en_US');

  static const List<(String, String, Color)> _attrSpecs = [
    ('batting', 'BATTING', Color(0xFF64B5F6)),
    ('bowling', 'BOWLING', Color(0xFFFFB74D)),
    ('fielding', 'FIELDING', Color(0xFF81C784)),
    ('stamina', 'STAMINA', Color(0xFFBA68C8)),
    ('consistency', 'CONSISTENCY', Color(0xFF4DD0E1)),
  ];

  late CricketPlayer _player;
  Timer? _ticker;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    // Refresh the energy refill countdown once per second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _train(String attrKey) async {
    if (_busy) return;
    if (!_player.canTrainAndUpgrade) {
      _toast('Premium and licensed cards have fixed stats.');
      return;
    }
    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      _toast('Sign in to train players.');
      return;
    }
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null) {
      _toast('Profile still loading…');
      return;
    }
    final now = DateTime.now();
    final energy = effectiveEnergy(
      profile.trainingEnergy,
      profile.trainingEnergyUpdatedAt,
      now,
    );
    if (energy <= 0) {
      _toast('Out of training energy — wait for refill or watch an ad.');
      return;
    }
    final overall = _player.attributes.overall;
    final potential = _player.effectivePotential;
    if (overall >= potential) {
      _toast('${_player.displayName} has hit potential ($potential OVR).');
      return;
    }
    final attrValue = _player.attributes.valueOf(attrKey);
    if (attrValue >= 100 || trainBaseGain(attrValue) == 0) {
      _toast('That attribute is maxed out.');
      return;
    }
    final cost = trainingCoinCost(overall);
    if (profile.coins < cost) {
      _toast('Not enough coins (need ${_coinFmt.format(cost)}).');
      return;
    }

    final result = computeTrainResult(
      attrValue: attrValue,
      overall: overall,
      potential: potential,
      roll: Random().nextDouble(),
    );
    if (result.outcome == TrainOutcome.capped) {
      _toast('No room to grow that stat right now.');
      return;
    }

    setState(() => _busy = true);
    final newPlayer = _player.copyWith(
      attributes: _player.attributes.bumped(attrKey, result.gain),
      potentialOverall: potential,
    );
    final stamp = energyStampAfterSpend(
      profile.trainingEnergy,
      profile.trainingEnergyUpdatedAt,
      now,
    );
    final newProfile = profile.copyWith(
      coins: profile.coins - cost,
      trainingEnergy: energy - 1,
      trainingEnergyUpdatedAt: stamp,
    );
    try {
      await ref.read(squadRepositoryProvider).upsertPlayer(uid, newPlayer);
      await ref.read(userRepositoryProvider).upsertProfile(newProfile);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('Could not save training: $e');
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _player = newPlayer;
      _busy = false;
    });
    _scheduleEnergyReminder(newProfile);
    _toast(_trainFeedback(result, attrKey));
  }

  void _scheduleEnergyReminder(UserProfile profile) {
    final now = DateTime.now();
    final toFull = timeToFullEnergy(
      profile.trainingEnergy,
      profile.trainingEnergyUpdatedAt,
      now,
    );
    if (toFull <= Duration.zero) {
      unawaited(LocalNotificationService.instance.cancelTrainingEnergyFull());
      unawaited(TrainingReminderStore.clearEnergyReminder());
    } else {
      final fullAt = now.add(toFull);
      unawaited(
        LocalNotificationService.instance.scheduleTrainingEnergyFull(
          fullAt: fullAt,
        ),
      );
      // Persist for the background isolate (backstop reminder + proof of run).
      unawaited(TrainingReminderStore.setEnergyFullAt(fullAt));
    }
  }

  String _trainFeedback(TrainResult r, String key) {
    final label = key.toUpperCase();
    switch (r.outcome) {
      case TrainOutcome.crit:
        return 'CRIT! $label +${r.gain}';
      case TrainOutcome.normal:
        return '$label +${r.gain}';
      case TrainOutcome.weak:
        return 'Tough session — $label +${r.gain}';
      case TrainOutcome.fail:
        return 'Training flopped — no gain this time.';
      case TrainOutcome.capped:
        return 'No room to grow.';
    }
  }

  Future<void> _watchAdForEnergy() async {
    if (_busy) return;
    final uid = ref.read(currentUidProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (uid == null || profile == null) {
      _toast('Sign in to refill energy.');
      return;
    }
    setState(() => _busy = true);
    final earned = await RewardedAdHelper.showRewardedAd();
    if (!mounted) return;
    if (!earned) {
      setState(() => _busy = false);
      _toast('Ad not completed — no energy added.');
      return;
    }
    final now = DateTime.now();
    final current = effectiveEnergy(
      profile.trainingEnergy,
      profile.trainingEnergyUpdatedAt,
      now,
    );
    final newEnergy = (current + kAdEnergyReward).clamp(0, kMaxTrainingEnergy);
    final newProfile = profile.copyWith(
      trainingEnergy: newEnergy,
      trainingEnergyUpdatedAt: now,
    );
    try {
      await ref.read(userRepositoryProvider).upsertProfile(newProfile);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('Could not add energy: $e');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _scheduleEnergyReminder(newProfile);
    _toast('Energy refilled +${newEnergy - current}.');
  }

  String _fmtCountdown(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _attrRow(
    String key,
    String label,
    int value,
    Color color, {
    required bool canTrain,
    required bool hasEnergy,
    required bool affordable,
    required bool atPotential,
  }) {
    final maxed = value >= 100 || trainBaseGain(value) == 0;
    final enabled =
        canTrain && !_busy && hasEnergy && affordable && !atPotential && !maxed;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _AttributeBar(label: label, value: value, color: color),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: enabled ? () => _train(key) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.neon,
              foregroundColor: GameColors.onNeonButton,
              disabledBackgroundColor: GameColors.muted.withValues(alpha: 0.2),
              disabledForegroundColor: GameColors.muted,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              maxed ? 'MAX' : 'TRAIN',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final coins = profile?.coins ?? 0;
    final now = DateTime.now();
    final energy =
        profile == null
            ? 0
            : effectiveEnergy(
              profile.trainingEnergy,
              profile.trainingEnergyUpdatedAt,
              now,
            );
    final nextIn =
        profile == null
            ? Duration.zero
            : timeToNextEnergy(
              profile.trainingEnergy,
              profile.trainingEnergyUpdatedAt,
              now,
            );

    final a = _player.attributes;
    final canTrain = _player.canTrainAndUpgrade;
    final potential = _player.effectivePotential;
    final atPotential = a.overall >= potential;
    final cost = trainingCoinCost(a.overall);
    final affordable = coins >= cost;
    final hasEnergy = energy > 0;
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: GameColors.neon,
            size: 20,
          ),
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
            child: _SummaryCard(player: _player),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _IdentityStrip(player: _player),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TrainingInfoStrip(
              coins: coins,
              potential: potential,
              energy: energy,
              maxEnergy: kMaxTrainingEnergy,
              nextIn: nextIn,
              cost: cost,
              canTrain: canTrain,
              fmtCountdown: _fmtCountdown,
              coinFmt: _coinFmt,
            ),
          ),
          if (!canTrain)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                _player.isRealPlayer
                    ? 'Licensed / real card — stats are fixed.'
                    : 'Premium card — stats are fixed (not trainable).',
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.9),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          const SizedBox(height: 10),
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
                    for (final spec in _attrSpecs) ...[
                      _attrRow(
                        spec.$1,
                        spec.$2,
                        a.valueOf(spec.$1),
                        spec.$3,
                        canTrain: canTrain,
                        hasEnergy: hasEnergy,
                        affordable: affordable,
                        atPotential: atPotential,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  !canTrain
                      ? 'This card cannot be trained.'
                      : atPotential
                      ? 'Potential reached — maxed at $potential OVR.'
                      : 'Each TRAIN spends 1 energy + ${_coinFmt.format(cost)} coins on one stat. It can crit or flop.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameColors.muted.withValues(alpha: 0.85),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed:
                      (canTrain && !_busy && energy < kMaxTrainingEnergy)
                          ? _watchAdForEnergy
                          : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GameColors.neon,
                    disabledForegroundColor: GameColors.muted,
                    side: BorderSide(
                      color:
                          (canTrain && energy < kMaxTrainingEnergy)
                              ? GameColors.neon.withValues(alpha: 0.6)
                              : GameColors.muted.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.ondemand_video_rounded, size: 22),
                  label: Text(
                    energy >= kMaxTrainingEnergy
                        ? 'ENERGY FULL'
                        : 'WATCH AD → +$kAdEnergyReward ENERGY',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
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

class _TrainingInfoStrip extends StatelessWidget {
  const _TrainingInfoStrip({
    required this.coins,
    required this.potential,
    required this.energy,
    required this.maxEnergy,
    required this.nextIn,
    required this.cost,
    required this.canTrain,
    required this.fmtCountdown,
    required this.coinFmt,
  });

  final int coins;
  final int potential;
  final int energy;
  final int maxEnergy;
  final Duration nextIn;
  final int cost;
  final bool canTrain;
  final String Function(Duration) fmtCountdown;
  final NumberFormat coinFmt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Coins: ${coinFmt.format(coins)}',
              style: TextStyle(
                color: GameColors.muted.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (canTrain)
              _chip(Icons.flag_rounded, 'POTENTIAL $potential', Colors.amber),
          ],
        ),
        if (canTrain) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: GameColors.neon, size: 20),
              const SizedBox(width: 6),
              Text(
                '$energy / $maxEnergy',
                style: const TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              if (energy < maxEnergy)
                Text(
                  '+1 in ${fmtCountdown(nextIn)}',
                  style: TextStyle(
                    color: GameColors.muted.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              const Spacer(),
              Text(
                'Train: ${coinFmt.format(cost)} c',
                style: TextStyle(
                  color: GameColors.muted.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.player});

  final CricketPlayer player;

  @override
  Widget build(BuildContext context) {
    final ovr = player.attributes.overall;
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
              width: 84,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: GameColors.neon.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
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
                    player.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF0F0F0),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${player.roleLabel} · ${player.countryLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: GameColors.neon.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((player.generatedBio ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      player.generatedBio!.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: GameColors.muted.withValues(alpha: 0.92),
                        fontSize: 12,
                        height: 1.32,
                      ),
                    ),
                  ],
                ],
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

class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({required this.player});

  final CricketPlayer player;

  @override
  Widget build(BuildContext context) {
    final items = [
      _IdentityItem(
        icon: Icons.sports_cricket_rounded,
        label:
            player.battingStyle?.trim().isNotEmpty == true
                ? player.battingStyle!.trim()
                : 'Batting style unknown',
      ),
      _IdentityItem(
        icon: Icons.sports_baseball_rounded,
        label:
            player.bowlingStyle?.trim().isNotEmpty == true
                ? player.bowlingStyle!.trim()
                : 'Bowling style unknown',
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _IdentityItem extends StatelessWidget {
  const _IdentityItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: GameColors.neon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GameColors.muted.withValues(alpha: 0.95),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
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
