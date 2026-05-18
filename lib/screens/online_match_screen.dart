import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/match_room.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/game_bottom_nav.dart';

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

  @override
  void dispose() {
    _joinCode.dispose();
    super.dispose();
  }

  void _clearError() => setState(() => _error = null);

  Future<void> _createRoom() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final room = await ref.read(matchRepositoryProvider).createRoom(hostUid: uid);
      if (!mounted) return;
      setState(() => _activeRoom = room);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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
      final existing = await ref.read(matchRepositoryProvider).getRoom(code);
      if (existing == null) {
        setState(() => _error = 'No room with that code.');
        return;
      }
      if (existing.hostUid == uid) {
        setState(() => _error = 'You are the host — share the code or start.');
        return;
      }
      await ref.read(matchRepositoryProvider).joinRoom(roomCode: code, guestUid: uid);
      final updated = await ref.read(matchRepositoryProvider).getRoom(code);
      if (!mounted) return;
      setState(() => _activeRoom = updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goLive(String roomId) {
    context.push('/match/live/$roomId');
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);
    final room = _activeRoom;

    final roomWatch = room != null ? ref.watch(matchRoomProvider(room.roomId)) : null;
    final liveRoom = roomWatch?.valueOrNull ?? room;

    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: GameColors.neon, size: 32),
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
              const Text('Sign in required.', style: TextStyle(color: Colors.white70))
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
                      borderSide: const BorderSide(color: GameColors.cardBorder),
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
                        liveRoom.guestUid != null && liveRoom.guestUid!.isNotEmpty
                            ? 'Guest joined — ready.'
                            : 'Waiting for guest to join…',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                  name: liveRoom.guestUid != null && liveRoom.guestUid!.isNotEmpty
                      ? (liveRoom.guestUid == uid ? 'You' : 'Joined')
                      : 'Waiting…',
                  ready: liveRoom.guestUid != null && liveRoom.guestUid!.isNotEmpty,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ||
                          liveRoom.guestUid == null ||
                          liveRoom.guestUid!.isEmpty
                      ? null
                      : () => _goLive(liveRoom.roomId),
                  style: FilledButton.styleFrom(
                    backgroundColor: GameColors.neon,
                    foregroundColor: GameColors.onNeonButton,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text(
                    'START LIVE MATCH',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _activeRoom = null;
                            _joinCode.clear();
                          }),
                  child: Text(
                    'Leave lobby',
                    style: TextStyle(color: GameColors.muted.withValues(alpha: 0.9)),
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
                    style: TextStyle(color: GameColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
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
