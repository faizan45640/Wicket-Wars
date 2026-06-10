import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../theme/game_colors.dart';

Future<void> showTrainingPlayerPicker(BuildContext parentContext, WidgetRef ref) async {
  final uid = ref.read(currentUidProvider);
  if (uid == null) {
    ScaffoldMessenger.of(parentContext).showSnackBar(
      const SnackBar(content: Text('Sign in to train your squad.')),
    );
    return;
  }
  final asyncSquad = ref.read(squadProvider(uid));
  final players = asyncSquad.valueOrNull ?? [];
  final trainable = players.where((p) => p.canTrainAndUpgrade).toList();
  if (players.isEmpty) {
    ScaffoldMessenger.of(parentContext).showSnackBar(
      const SnackBar(
        content: Text('Your squad is empty. Open a pack to add players first.'),
      ),
    );
    return;
  }
  if (trainable.isEmpty) {
    ScaffoldMessenger.of(parentContext).showSnackBar(
      const SnackBar(
        content: Text(
          'No trainable players — premium and licensed cards have fixed stats. Add or unlock free custom players.',
        ),
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: parentContext,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) {
          return Material(
            color: GameColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, color: GameColors.neon, size: 26),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'SELECT PLAYER TO TRAIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Free custom players only (premium / licensed cards are locked).',
                  style: TextStyle(
                    color: GameColors.muted.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: trainable.length,
                    itemBuilder: (context, i) {
                      final p = trainable[i];
                      final ovr = p.attributes.overall;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              parentContext.push(
                                '/player/${p.id}',
                                extra: p,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: GameColors.bg,
                                    child: Text(
                                      p.displayName.isNotEmpty
                                          ? p.displayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: GameColors.neon,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.displayName,
                                          style: const TextStyle(
                                            color: Color(0xFFEEEEEE),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'FREE · TRAINABLE',
                                          style: TextStyle(
                                            color: GameColors.muted.withValues(alpha: 0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$ovr',
                                    style: const TextStyle(
                                      color: GameColors.neon,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: GameColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
