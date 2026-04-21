import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dark cricket dashboard — matches Wicket Wars home mockup.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  static final NumberFormat _coinFormat = NumberFormat.decimalPattern('en_US');

  static const _displayName = 'Player123';
  static const _coins = 1500;
  static const _rankingPoints = 875;

  static const _bg = Color(0xFF121212);
  static const _card = Color(0xFF1E1E1E);
  static const _cardBorder = Color(0xFF2A2A2A);
  static const _neon = Color(0xFF39FF14);
  static const _muted = Color(0xFF9E9E9E);
  static const _onNeonButton = Color(0xFF0A2E0A);

  String get _nameInitial =>
      _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'CRICKET SIM MASTER',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: _neon),
            tooltip: 'Profile',
            onPressed: () => setState(() => _navIndex = 3),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildPlayMatchButton(),
              const SizedBox(height: 16),
              _buildMenuCard(
                icon: Icons.groups_outlined,
                title: 'MY SQUAD',
                subtitle: '11 Active Players',
                showChevron: true,
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.fitness_center,
                title: 'TRAINING',
                subtitle: 'Improve Skills',
                newBadge: true,
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.emoji_events_outlined,
                title: 'LEADERBOARD',
                subtitle: 'Rank #4,210',
                showChevron: true,
              ),
              const SizedBox(height: 12),
              _buildDailyRewardCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// Wireframe: large initial avatar, name + coins + ranking stacked on the right.
  Widget _buildProfileSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _neon, width: 2),
          ),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: _card,
            child: Text(
              _nameInitial,
              style: const TextStyle(
                color: _neon,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                _displayName,
                style: TextStyle(
                  color: _neon,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'COINS: ${_coinFormat.format(_coins)}',
                    style: TextStyle(
                      color: _muted.withValues(alpha: 0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.star_border_rounded, color: _neon.withValues(alpha: 0.9), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'RANKING POINTS: ${_coinFormat.format(_rankingPoints)}',
                    style: TextStyle(
                      color: _muted.withValues(alpha: 0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayMatchButton() {
    return Material(
      color: _neon,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START COMPETITION',
                      style: TextStyle(
                        color: _onNeonButton.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PLAY MATCH',
                      style: TextStyle(
                        color: _onNeonButton,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _onNeonButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_cricket, color: _neon, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showChevron = false,
    bool newBadge = false,
  }) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: _muted, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _muted.withValues(alpha: 0.95),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (newBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else if (showChevron)
                Icon(Icons.chevron_right, color: _muted.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyRewardCard() {
    return DottedBorder(
      color: _neon,
      strokeWidth: 1.8,
      dashPattern: const [6, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: _card,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, color: _neon, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAILY REWARD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Available Now',
                          style: TextStyle(
                            color: _neon,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: _neon,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: _cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'HOME',
              selected: _navIndex == 0,
              onTap: () => setState(() => _navIndex = 0),
            ),
            _NavItem(
              icon: Icons.groups_outlined,
              label: 'SQUAD',
              selected: _navIndex == 1,
              onTap: () => setState(() => _navIndex = 1),
            ),
            _NavItem(
              icon: Icons.sports_cricket,
              label: 'MATCHES',
              selected: _navIndex == 2,
              onTap: () => setState(() => _navIndex = 2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'PROFILE',
              selected: _navIndex == 3,
              onTap: () => setState(() => _navIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _neon = _HomeScreenState._neon;
  static const _muted = _HomeScreenState._muted;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _neon : _muted.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
              shadows: selected
                  ? [
                      Shadow(
                        color: _neon.withValues(alpha: 0.75),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            if (selected)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: _neon,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
