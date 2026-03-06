import 'package:cric_rec/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cric_rec/core/services/statistics_service.dart';

final _statsService = StatisticsService();

class StatisticsDashboardScreen extends StatefulWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  State<StatisticsDashboardScreen> createState() =>
      _StatisticsDashboardScreenState();
}

class _StatisticsDashboardScreenState extends State<StatisticsDashboardScreen> {
  bool _isLoading = true;
  PlayerStatistics? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      final stats = await _statsService.calculatePlayerStatistics(uid);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Statistics'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      )
          : _error != null
          ? _buildErrorView()
          : _buildStatisticsView(),
    );
  }

  Widget _buildErrorView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          const Text(
            'Failed to load statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsView() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_stats == null) return const Center(child: Text('No statistics available'));

    if (_stats!.totalMatches == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.sports_cricket, size: 80, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('No matches played yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Play some matches to see your statistics!',
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallStatsCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('🏏 Batting Statistics'),
            _buildBattingStatsCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('⚾ Bowling Statistics'),
            _buildBowlingStatsCard(),
            const SizedBox(height: 16),
            if (_stats!.recentScores.isNotEmpty) ...[
              _buildSectionTitle('📈 Recent Form (Last 5 Matches)'),
              _buildRecentFormCard(),
              const SizedBox(height: 16),
            ],
            _buildSectionTitle('🏆 Milestones'),
            _buildMilestonesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOverallStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.8), AppTheme.primary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          const Text('Overall Performance',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverallStatItem(Icons.sports_cricket, 'Matches', _stats!.totalMatches.toString()),
              _buildOverallStatItem(Icons.emoji_events, 'Won', _stats!.matchesWon.toString()),
              _buildOverallStatItem(Icons.trending_up, 'Win %', '${_stats!.winPercentage.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildBattingStatsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _buildStatRow('Total Runs', _stats!.totalRuns.toString())),
            Expanded(child: _buildStatRow('Balls Faced', _stats!.ballsFaced.toString())),
          ]),
          const Divider(height: 24),
          Row(children: [
            Expanded(child: _buildStatRow('Average', _stats!.battingAverage.toStringAsFixed(2))),
            Expanded(child: _buildStatRow('Strike Rate', _stats!.strikeRate.toStringAsFixed(2))),
          ]),
          const Divider(height: 24),
          Row(children: [
            Expanded(child: _buildStatRow('Highest Score', _stats!.highestScore.toString())),
            Expanded(child: _buildStatRow('50s / 100s', '${_stats!.fifties} / ${_stats!.centuries}')),
          ]),
          const Divider(height: 24),
          Row(children: [
            Expanded(child: _buildStatRow('Fours', _stats!.fours.toString())),
            Expanded(child: _buildStatRow('Sixes', _stats!.sixes.toString())),
            Expanded(child: _buildStatRow('Ducks', _stats!.ducks.toString())),
          ]),
        ],
      ),
    );
  }

  Widget _buildBowlingStatsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _buildStatRow('Wickets', _stats!.totalWickets.toString())),
            Expanded(child: _buildStatRow('Balls Bowled', _stats!.ballsBowled.toString())),
          ]),
          const Divider(height: 24),
          Row(children: [
            Expanded(child: _buildStatRow('Average', _stats!.bowlingAverage.toStringAsFixed(2))),
            Expanded(child: _buildStatRow('Economy', _stats!.economy.toStringAsFixed(2))),
          ]),
          const Divider(height: 24),
          Row(children: [
            Expanded(child: _buildStatRow('Best Figures', _stats!.bestBowling)),
            Expanded(child: _buildStatRow('3W / 5W', '${_stats!.threeWickets} / ${_stats!.fiveWickets}')),
          ]),
          const Divider(height: 24),
          _buildStatRow('Maidens', _stats!.maidens.toString()),
        ],
      ),
    );
  }

  Widget _buildRecentFormCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Batting Scores', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140, // 🟢 Increased to 140 to prevent overflow
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _stats!.recentScores.asMap().entries.map((entry) {
                final index = entry.key;
                final score = entry.value;
                final maxScore = _stats!.recentScores.reduce((a, b) => a > b ? a : b);
                final double targetHeight = maxScore > 0 ? (score / maxScore) * 85 : 10;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min, // 🟢 Force Column to only take needed space
                  children: [
                    Text(score.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 150)), // Staggered growth
                      tween: Tween(begin: 0.0, end: targetHeight),
                      curve: Curves.easeOut,
                      builder: (context, animatedHeight, child) {
                        return Container(
                          width: 40,
                          height: animatedHeight,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text('M${_stats!.recentScores.length - index}',
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.6))),
                  ],
                );
              }).toList(),
            ),
          ),
          if (_stats!.recentWickets.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Bowling Wickets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _stats!.recentWickets.asMap().entries.map((entry) {
                final index = entry.key;
                final wickets = entry.value;
                return Column(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: wickets > 0 ? AppTheme.warning.withOpacity(0.2) : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(wickets.toString(),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                color: wickets > 0 ? AppTheme.warning : colorScheme.onSurface.withOpacity(0.4))),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('M${_stats!.recentWickets.length - index}',
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.6))),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestonesCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildMilestoneItem(Icons.stars, 'Centuries', _stats!.centuries, AppTheme.warning),
          if (_stats!.centuries > 0) const Divider(height: 20),
          _buildMilestoneItem(Icons.star_half, 'Half Centuries', _stats!.fifties, AppTheme.extraOrange),
          const Divider(height: 20),
          _buildMilestoneItem(Icons.sports_baseball, '5 Wicket Hauls', _stats!.fiveWickets, AppTheme.boundarySix),
          const Divider(height: 20),
          _buildMilestoneItem(Icons.sports, '3 Wicket Hauls', _stats!.threeWickets, AppTheme.info),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(IconData icon, String label, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}