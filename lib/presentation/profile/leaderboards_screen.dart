import 'package:cric_rec/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Import leaderboard service (adjust path)
import 'package:cric_rec/core/services/leaderboard_service.dart';

class LeaderboardsScreen extends StatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _leaderboardService = LeaderboardService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Leaderboards'),
        backgroundColor: AppTheme.warning,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '🏏 Runs'),
            Tab(text: '⚾ Wickets'),
            Tab(text: '📈 Strike Rate'),
            Tab(text: '💨 Economy'),
            Tab(text: '🎮 Matches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab('runs'),
          _buildLeaderboardTab('wickets'),
          _buildLeaderboardTab('strikeRate'),
          _buildLeaderboardTab('economy'),
          _buildLeaderboardTab('matches'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(String category) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<LeaderboardEntry>>(
      future: _getLeaderboardData(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load leaderboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No data yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Play some matches to see rankings!',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return _buildLeaderboardCard(
                entry: entries[index],
                rank: index + 1,
                category: category,
              );
            },
          ),
        );
      },
    );
  }

  Future<List<LeaderboardEntry>> _getLeaderboardData(String category) async {
    switch (category) {
      case 'runs':
        return await _leaderboardService.getTopRunScorers();
      case 'wickets':
        return await _leaderboardService.getTopWicketTakers();
      case 'strikeRate':
        return await _leaderboardService.getBestStrikeRates();
      case 'economy':
        return await _leaderboardService.getBestEconomy();
      case 'matches':
        return await _leaderboardService.getMostMatchesPlayed();
      default:
        return [];
    }
  }

  Widget _buildLeaderboardCard({
    required LeaderboardEntry entry,
    required int rank,
    required String category,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser = entry.playerId == currentUserId;

    Color rankColor;
    IconData rankIcon;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = colorScheme.onSurface.withOpacity(0.4);
        rankIcon = Icons.circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.primaryContainer
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? colorScheme.primary : colorScheme.outline,
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (rank <= 3)
                    Icon(rankIcon, color: rankColor, size: 20),
                  Text(
                    rank.toString(),
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                      fontSize: rank <= 3 ? 12 : 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.playerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getCategoryLabel(category),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Value
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatValue(entry.value, category),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getCategoryColor(category),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'runs':
        return 'Total Runs';
      case 'wickets':
        return 'Total Wickets';
      case 'strikeRate':
        return 'Strike Rate (min 100 balls)';
      case 'economy':
        return 'Economy Rate (min 30 balls)';
      case 'matches':
        return 'Matches Played';
      default:
        return '';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'runs':
        return AppTheme.primary;
      case 'wickets':
        return AppTheme.wicketRed;
      case 'strikeRate':
        return AppTheme.info;
      case 'economy':
        return AppTheme.boundarySix;
      case 'matches':
        return AppTheme.warning;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatValue(int value, String category) {
    switch (category) {
      case 'strikeRate':
        return value.toString();
      case 'economy':
        return (value / 10).toStringAsFixed(2); // Economy stored as int * 10
      default:
        return value.toString();
    }
  }
}