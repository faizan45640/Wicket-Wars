import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/cricket_player.dart';
import '../data/models/match_room.dart';
import '../data/models/pitch_condition.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/game_bottom_nav.dart';
import '../widgets/monetization_banner.dart';

class OnlineMatchScreen extends ConsumerStatefulWidget {
  const OnlineMatchScreen({super.key});

  @override
  ConsumerState<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends ConsumerState<OnlineMatchScreen> {
  final _joinCode = TextEditingController();
  var _busy = false;
  String? _error;
  MatchRoom? _activeRoom;
  final Set<String> _selectedXi = {};

  @override
  void dispose() {
    _joinCode.dispose();
    super.dispose();
  }

  void _clearError() => setState(() => _error = null);

  String _friendlyFirebaseError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied') ||
        text.contains('PERMISSION_DENIED')) {
      return 'Firebase permission denied. Make sure Firestore rules are deployed and you are signed in.';
    }
    if (text.contains('not-found') || text.contains('NOT_FOUND')) {
      return 'Match backend is not deployed yet. Deploy the Firebase functions first.';
    }
    if (text.contains('unavailable') || text.contains('UNAVAILABLE')) {
      return 'Firebase is temporarily unavailable. Check internet and try again.';
    }
    return 'Could not complete match action. Please try again.';
  }

  Future<void> _createRoom() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final room = await ref
          .read(matchRepositoryProvider)
          .createRoom(hostUid: uid);
      if (!mounted) return;
      setState(() {
        _activeRoom = room;
        _selectedXi.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyFirebaseError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final code = _joinCode.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'Enter a room code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(matchRepositoryProvider)
          .joinRoom(roomCode: code, guestUid: uid);
      if (!mounted) return;
      setState(() {
        _activeRoom = MatchRoom(
          roomId: code,
          roomCode: code,
          status: MatchRoomStatus.selectingXi,
          pitch: PitchCondition.balanced,
          guestUid: uid,
        );
        _selectedXi.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyFirebaseError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goLive(String roomId) {
    context.push('/match/live/$roomId');
  }

  Future<void> _lockSelectedXi(
    MatchRoom room,
    List<CricketPlayer> squad,
  ) async {
    final selectedIds = _effectiveSelectedIds(squad);
    if (selectedIds.length != 11) {
      setState(() => _error = 'Select exactly 11 available players.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(matchRepositoryProvider)
          .lockPlayingXi(roomId: room.roomId, playerIds: selectedIds);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyFirebaseError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _effectiveSelectedIds(List<CricketPlayer> squad) {
    final available = [...squad.where((p) => p.availableForXi)]
      ..sort((a, b) => b.attributes.overall.compareTo(a.attributes.overall));
    final availableIds = available.map((p) => p.id).toSet();
    final explicit = _selectedXi.where(availableIds.contains).toList();
    if (explicit.isNotEmpty) return explicit;
    return available.take(11).map((p) => p.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);
    final room = _activeRoom;
    final squadAsync = uid != null ? ref.watch(squadProvider(uid)) : null;

    final roomWatch =
        room != null ? ref.watch(matchRoomProvider(room.roomId)) : null;
    final liveRoom = roomWatch?.valueOrNull ?? room;

    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: GameColors.neon,
            size: 32,
          ),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'ONLINE MATCH LOBBY',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (uid == null)
              const Text(
                'Sign in required.',
                style: TextStyle(color: Colors.white70),
              )
            else ...[
              if (_error != null) ...[
                AuthErrorBanner(
                  message: _error!,
                  onDismiss: _clearError,
                  semanticsLabel: 'Lobby error',
                ),
                const SizedBox(height: 16),
              ],
              if (liveRoom == null) ...[
                FilledButton.icon(
                  onPressed: _busy ? null : _createRoom,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('CREATE ROOM'),
                  style: FilledButton.styleFrom(
                    backgroundColor: GameColors.neon,
                    foregroundColor: GameColors.onNeonButton,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _joinCode,
                  onChanged: (_) => _clearError(),
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Room code',
                    labelStyle: TextStyle(color: GameColors.muted),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: GameColors.cardBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: GameColors.neon),
                    ),
                    filled: true,
                    fillColor: GameColors.card,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _joinRoom,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GameColors.neon,
                    side: const BorderSide(color: GameColors.neon),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('JOIN WITH CODE'),
                ),
                const SizedBox(height: 18),
                const Center(child: MonetizationBanner()),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GameColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GameColors.neon, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'ROOM CODE',
                        style: TextStyle(
                          color: GameColors.muted.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        liveRoom.roomCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        liveRoom.guestUid != null &&
                                liveRoom.guestUid!.isNotEmpty
                            ? 'Guest joined — ready.'
                            : 'Waiting for guest to join…',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _lobbyCard(
                  label: liveRoom.hostUid == uid ? 'You (host)' : 'Host',
                  name: liveRoom.hostUid == uid ? 'You' : 'Other player',
                  ready: liveRoom.hostUid != null,
                ),
                const SizedBox(height: 12),
                _lobbyCard(
                  label: 'Guest',
                  name:
                      liveRoom.guestUid != null && liveRoom.guestUid!.isNotEmpty
                          ? (liveRoom.guestUid == uid ? 'You' : 'Joined')
                          : 'Waiting…',
                  ready:
                      liveRoom.guestUid != null &&
                      liveRoom.guestUid!.isNotEmpty,
                ),
                const SizedBox(height: 24),
                if (liveRoom.guestUid != null && liveRoom.guestUid!.isNotEmpty)
                  _xiSelectionSection(liveRoom, uid, squadAsync),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      _busy
                          ? null
                          : () => setState(() {
                            _activeRoom = null;
                            _joinCode.clear();
                            _selectedXi.clear();
                          }),
                  child: Text(
                    'Leave lobby',
                    style: TextStyle(
                      color: GameColors.muted.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 2),
    );
  }

  Widget _xiSelectionSection(
    MatchRoom room,
    String uid,
    AsyncValue<List<CricketPlayer>>? squadAsync,
  ) {
    final youHost = room.hostUid == uid;
    final myLocked = youHost ? room.hostXiLocked : room.guestXiLocked;
    final bothLocked = room.hostXiLocked && room.guestXiLocked;
    if (bothLocked) {
      return FilledButton(
        onPressed: _busy ? null : () => _goLive(room.roomId),
        style: FilledButton.styleFrom(
          backgroundColor: GameColors.neon,
          foregroundColor: GameColors.onNeonButton,
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        child: const Text(
          'START LIVE MATCH',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      );
    }
    if (myLocked) {
      return const Text(
        'Your XI is locked. Waiting for the other player.',
        style: TextStyle(color: Colors.white70),
      );
    }
    if (squadAsync == null) {
      return const Text(
        'Squad unavailable.',
        style: TextStyle(color: Colors.white70),
      );
    }
    return squadAsync.when(
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: GameColors.neon),
          ),
      error:
          (e, _) => Text(
            'Could not load squad: $e',
            style: TextStyle(color: Colors.red.shade200),
          ),
      data: (squad) {
        final available = [
          ...squad.where((p) => p.availableForXi),
        ]..sort((a, b) => b.attributes.overall.compareTo(a.attributes.overall));
        final selectedIds = _effectiveSelectedIds(available).toSet();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'SELECT PLAYING XI',
                    style: TextStyle(
                      color: GameColors.neon,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${selectedIds.length}/11',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...available.take(15).map((p) {
              final selected = selectedIds.contains(p.id);
              return CheckboxListTile(
                value: selected,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: GameColors.neon,
                checkColor: GameColors.onNeonButton,
                title: Text(
                  p.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${p.roleLabel} · OVR ${p.attributes.overall}',
                  style: TextStyle(color: GameColors.muted),
                ),
                onChanged:
                    _busy
                        ? null
                        : (value) {
                          setState(() {
                            if (_selectedXi.isEmpty) {
                              _selectedXi.addAll(selectedIds);
                            }
                            if (value == true) {
                              if (_selectedXi.length < 11 || selected) {
                                _selectedXi.add(p.id);
                              }
                            } else {
                              _selectedXi.remove(p.id);
                            }
                          });
                        },
              );
            }),
            const SizedBox(height: 12),
            FilledButton(
              onPressed:
                  _busy || selectedIds.length != 11
                      ? null
                      : () => _lockSelectedXi(room, available),
              style: FilledButton.styleFrom(
                backgroundColor: GameColors.neon,
                foregroundColor: GameColors.onNeonButton,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Text(
                _busy ? 'LOCKING...' : 'LOCK SELECTED XI',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _lobbyCard({
    required String label,
    required String name,
    required bool ready,
  }) {
    return Card(
      color: GameColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GameColors.cardBorder, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GameColors.bg,
                border: Border.all(color: GameColors.neon, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: GameColors.neon,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: GameColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ready ? 'Ready' : 'Waiting…',
                    style: TextStyle(
                      color: ready ? GameColors.neon : Colors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
