import 'package:cloud_functions/cloud_functions.dart';
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
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unauthenticated':
          return 'You appear to be signed out. Log out and back in, then try again.';
        case 'permission-denied':
          return 'Could not access this match. Make sure you are signed in and try again.';
        case 'not-found':
          return 'Match service is not ready yet. Please try again in a moment.';
        case 'unavailable':
          return 'Match service is temporarily unavailable. Check internet and try again.';
        default:
          return 'Match error [${error.code}]: ${error.message ?? error.details ?? 'unknown'}';
      }
    }
    final text = error.toString();
    if (text.contains('permission-denied') ||
        text.contains('PERMISSION_DENIED')) {
      return 'Could not access this match. Make sure you are signed in and try again.';
    }
    if (text.contains('not-found') || text.contains('NOT_FOUND')) {
      return 'Match service is not ready yet. Please try again in a moment.';
    }
    if (text.contains('unavailable') || text.contains('UNAVAILABLE')) {
      return 'Match service is temporarily unavailable. Check internet and try again.';
    }
    return 'Match error: $text';
  }

  Future<void> _createRoom({
    required int overs,
    required PitchCondition pitch,
  }) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final room = await ref
          .read(matchRepositoryProvider)
          .createRoom(hostUid: uid, overs: overs, pitch: pitch);
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

  Future<void> _showCreateRoomSettings() async {
    var overs = 20;
    var pitch = PitchCondition.balanced;
    const oversOptions = [1, 5, 10, 20];
    const pitchOptions = PitchCondition.values;
    String pitchLabel(PitchCondition p) {
      switch (p) {
        case PitchCondition.flat:
          return 'Flat · big scores';
        case PitchCondition.grassy:
          return 'Grassy · seam friendly';
        case PitchCondition.balanced:
          return 'Balanced';
      }
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: GameColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: GameColors.muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MATCH SETTINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You host, so you set the rules.',
                    style: TextStyle(
                      color: GameColors.muted.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'OVERS PER INNINGS',
                    style: TextStyle(
                      color: GameColors.neon,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final o in oversOptions) ...[
                        Expanded(
                          child: _settingChip(
                            label: '$o',
                            sublabel: o == 1 ? 'over' : 'overs',
                            selected: overs == o,
                            onTap: () => setSheetState(() => overs = o),
                          ),
                        ),
                        if (o != oversOptions.last) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'PITCH',
                    style: TextStyle(
                      color: GameColors.neon,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final p in pitchOptions) ...[
                    _settingRow(
                      label: pitchLabel(p),
                      selected: pitch == p,
                      onTap: () => setSheetState(() => pitch = p),
                    ),
                    if (p != pitchOptions.last) const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('CREATE ROOM'),
                    style: FilledButton.styleFrom(
                      backgroundColor: GameColors.neon,
                      foregroundColor: GameColors.onNeonButton,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (confirmed == true) {
      await _createRoom(overs: overs, pitch: pitch);
    }
  }

  Widget _settingChip({
    required String label,
    required String sublabel,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? GameColors.neon.withValues(alpha: 0.18)
              : GameColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? GameColors.neon : GameColors.cardBorder,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? GameColors.neon : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                color: GameColors.muted.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? GameColors.neon.withValues(alpha: 0.18)
              : GameColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? GameColors.neon : GameColors.cardBorder,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? GameColors.neon : GameColors.muted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _showJoinDialog() async {
    final shouldJoin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: GameColors.card,
          title: const Text(
            'Join with code',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: _joinCode,
            autofocus: true,
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
              fillColor: GameColors.bg,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: GameColors.muted),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: GameColors.neon,
                foregroundColor: GameColors.onNeonButton,
              ),
              child: const Text('JOIN'),
            ),
          ],
        );
      },
    );
    if (shouldJoin == true) await _joinRoom();
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

  Future<void> _lockStrongestXi(MatchRoom room) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(matchRepositoryProvider)
          .lockStrongestXi(roomId: room.roomId);
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
        child:
            uid == null
                ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Sign in required.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                : liveRoom == null
                ? _buildHub(uid)
                : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error != null) ...[
                      AuthErrorBanner(
                        message: _error!,
                        onDismiss: _clearError,
                        semanticsLabel: 'Lobby error',
                      ),
                      const SizedBox(height: 16),
                    ],
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
                      Row(
                        children: [
                          _settingsPill(
                            Icons.sports_cricket_rounded,
                            '${liveRoom.oversPerInnings} ${liveRoom.oversPerInnings == 1 ? 'over' : 'overs'}',
                          ),
                          const SizedBox(width: 8),
                          _settingsPill(
                            Icons.terrain_rounded,
                            '${liveRoom.pitch.name[0].toUpperCase()}'
                                '${liveRoom.pitch.name.substring(1)} pitch',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                ),
      ),
      bottomNavigationBar: const GameBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildHub(String uid) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final wins = profile?.wins ?? 0;
    final losses = profile?.losses ?? 0;
    final points = profile?.rankingPoints ?? 0;
    final online =
        60 + (DateTime.now().hour * 17 + DateTime.now().day * 11) % 280;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AuthErrorBanner(
              message: _error!,
              onDismiss: _clearError,
              semanticsLabel: 'Lobby error',
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _statTile(
                  Icons.emoji_events_rounded,
                  'RECORD',
                  '$wins W · $losses L',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(Icons.bolt_rounded, 'RANK PTS', '$points'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  Icons.wifi_tethering_rounded,
                  'ONLINE',
                  '$online',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: _lobbyHero()),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : _showCreateRoomSettings,
            icon: const Icon(Icons.add_rounded),
            label: const Text('CREATE ROOM (vs friend)'),
            style: FilledButton.styleFrom(
              backgroundColor: GameColors.neon,
              foregroundColor: GameColors.onNeonButton,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _showJoinDialog,
            icon: const Icon(Icons.vpn_key_rounded),
            label: const Text('JOIN WITH CODE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: GameColors.neon,
              side: const BorderSide(color: GameColors.neon),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Host a room and share the code, or join a friend with their code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.8),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: GameColors.neon, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.9),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lobbyHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GameColors.neon.withValues(alpha: 0.18), GameColors.card],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameColors.neon, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GameColors.neon.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: GameColors.neon,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PLAY ONLINE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a room to host a match and share the code with a friend, '
            'or join their room with a code below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameColors.muted.withValues(alpha: 0.95),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
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
          (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Could not load your squad right now. You can still auto-select your strongest XI and continue.',
                style: TextStyle(color: Colors.red.shade200),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _lockStrongestXi(room),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(_busy ? 'LOCKING...' : 'AUTO SELECT XI'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GameColors.neon,
                  side: const BorderSide(color: GameColors.neon),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
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

  Widget _settingsPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GameColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameColors.neon.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: GameColors.neon, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
