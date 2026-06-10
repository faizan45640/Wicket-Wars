import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../auth/auth_messages.dart';
import '../auth/auth_validators.dart';
import '../data/models/match_summary.dart';
import '../data/models/user_profile.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/game_bottom_nav.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static final _fmt = NumberFormat.decimalPattern('en_US');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const neonGreen = Color(0xFF00FF00);
    final profileAsync = ref.watch(userProfileProvider);
    final uid = ref.watch(currentUidProvider);
    final historyAsync =
        uid != null
            ? ref.watch(matchHistoryProvider(uid))
            : const AsyncValue<List<MatchSummary>>.data([]);

    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: neonGreen, size: 32),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: profileAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: GameColors.neon),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'Error: $e',
                style: TextStyle(color: Colors.red.shade200),
              ),
            ),
        data: (profile) {
          final p = profile;
          if (p == null) {
            return const Center(
              child: Text(
                'No profile',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          final totalRuns = historyAsync.maybeWhen(
            data: (h) => h.fold<int>(0, (s, m) => s + m.runsFor),
            orElse: () => p.totalRunsScored,
          );
          final winRate =
              p.matchesPlayed > 0
                  ? ((p.wins / p.matchesPlayed) * 100).round()
                  : 0;

          final initial =
              p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?';
          final stats = <(IconData, String, String)>[
            (Icons.sports_cricket_outlined, 'Matches', '${p.matchesPlayed}'),
            (Icons.emoji_events_outlined, 'Wins', '${p.wins}'),
            (Icons.close_rounded, 'Losses', '${p.losses}'),
            (Icons.percent_outlined, 'Win rate', '$winRate%'),
            (Icons.sports_baseball_outlined, 'Runs', _fmt.format(totalRuns)),
            (Icons.star_border_rounded, 'Ranking', _fmt.format(p.rankingPoints)),
            (
              Icons.local_fire_department_outlined,
              'Streak',
              '${p.dailyStreak}d',
            ),
            (Icons.monetization_on_outlined, 'Coins', _fmt.format(p.coins)),
          ];
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: GameColors.bg,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: neonGreen, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: neonGreen.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: GameColors.bg,
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: neonGreen,
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: neonGreen.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          p.displayName,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit display name',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showEditNameDialog(context, ref, p),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: GameColors.neon,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  if (p.email != null && p.email!.isNotEmpty)
                    Center(
                      child: Text(
                        p.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: GameColors.muted.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      p.leagueTier,
                      style: TextStyle(
                        color: GameColors.neon.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 0; i < stats.length; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: i == stats.length - 1 ? 0 : 10,
                              ),
                              child: _statCell(
                                stats[i].$1,
                                stats[i].$2,
                                stats[i].$3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () async {
                      final confirmed = await _confirmSignOut(context);
                      if (confirmed != true) return;
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE57373),
                      side: const BorderSide(color: Color(0xFF4A2C2C)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text(
                      'Log out',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 3),
    );
  }

  static Future<bool?> _confirmSignOut(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: GameColors.card,
            title: const Text('Log out'),
            content: const Text('End this Wicket Wars session?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE57373),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Log out'),
              ),
            ],
          ),
    );
  }

  static Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final controller = TextEditingController(text: profile.displayName);
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  backgroundColor: GameColors.card,
                  title: const Text('Edit display name'),
                  content: Form(
                    key: formKey,
                    child: TextFormField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        counterText: '',
                      ),
                      maxLength: 20,
                      validator: AuthValidators.displayName,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed:
                          saving
                              ? null
                              : () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                final name = controller.text.trim();
                                setState(() => saving = true);
                                try {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .updateDisplayName(name);
                                  await ref
                                      .read(userRepositoryProvider)
                                      .upsertProfile(
                                        profile.copyWith(displayName: name),
                                      );
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(authErrorMessage(e)),
                                    ),
                                  );
                                  setState(() => saving = false);
                                }
                              },
                      child:
                          saving
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                              : const Text('Save'),
                    ),
                  ],
                ),
          ),
    );

    controller.dispose();
  }

  static Widget _statCell(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GameColors.neon.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: GameColors.neon, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
