import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerStatistics {
  // Basic Info
  final String playerId;
  final String playerName;

  // Match Stats
  final int totalMatches;
  final int matchesWon;
  final int matchesLost;
  final double winPercentage;

  // Batting Stats
  final int totalRuns;
  final int ballsFaced;
  final double battingAverage;
  final double strikeRate;
  final int highestScore;
  final int fifties;
  final int centuries;
  final int fours;
  final int sixes;
  final int ducks;

  // Bowling Stats
  final int totalWickets;
  final int ballsBowled;
  final int runsConceded;
  final double bowlingAverage;
  final double economy;
  final double strikeRateBowling;
  final String bestBowling; // e.g., "4/15"
  final int threeWickets;
  final int fiveWickets;
  final int maidens;

  // Recent Form (last 5 matches)
  final List<int> recentScores;
  final List<int> recentWickets;

  PlayerStatistics({
    required this.playerId,
    required this.playerName,
    required this.totalMatches,
    required this.matchesWon,
    required this.matchesLost,
    required this.winPercentage,
    required this.totalRuns,
    required this.ballsFaced,
    required this.battingAverage,
    required this.strikeRate,
    required this.highestScore,
    required this.fifties,
    required this.centuries,
    required this.fours,
    required this.sixes,
    required this.ducks,
    required this.totalWickets,
    required this.ballsBowled,
    required this.runsConceded,
    required this.bowlingAverage,
    required this.economy,
    required this.strikeRateBowling,
    required this.bestBowling,
    required this.threeWickets,
    required this.fiveWickets,
    required this.maidens,
    required this.recentScores,
    required this.recentWickets,
  });
}

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate comprehensive statistics for a player
  Future<PlayerStatistics> calculatePlayerStatistics(String playerId) async {
    try {
      // Get all completed matches
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'completed')
          .get();

      // Initialize stats
      int totalMatches = 0;
      int matchesWon = 0;
      int matchesLost = 0;

      // Batting stats
      int totalRuns = 0;
      int ballsFaced = 0;
      int highestScore = 0;
      int fifties = 0;
      int centuries = 0;
      int fours = 0;
      int sixes = 0;
      int ducks = 0;
      int timesOut = 0;

      // Bowling stats
      int totalWickets = 0;
      int ballsBowled = 0;
      int runsConceded = 0;
      int bestWickets = 0;
      int bestRuns = 999;
      int threeWickets = 0;
      int fiveWickets = 0;
      int maidens = 0;

      // Recent form
      List<Map<String, dynamic>> recentMatches = [];

      // Get player info
      final playerDoc = await _firestore.collection('players').doc(playerId).get();
      final playerName = playerDoc.exists
          ? (playerDoc.data()?['fullName'] ?? 'Player')
          : 'Player';

      // Process each match
      for (final matchDoc in matchesSnapshot.docs) {
        final matchData = matchDoc.data();
        final matchId = matchDoc.id;

        // Check if player participated
        final teamA = (matchData['teamA']?['players'] ?? []) as List;
        final teamB = (matchData['teamB']?['players'] ?? []) as List;

        final isInTeamA = teamA.any((p) => p['uid'] == playerId);
        final isInTeamB = teamB.any((p) => p['uid'] == playerId);

        if (!isInTeamA && !isInTeamB) continue;

        totalMatches++;

        // Check if won
        final winner = matchData['winner'];
        if ((winner == 'teamA' && isInTeamA) ||
            (winner == 'teamB' && isInTeamB)) {
          matchesWon++;
        } else if (winner != null && winner != 'tie') {
          matchesLost++;
        }

        // Get balls for this match
        final ballsSnapshot = await _firestore
            .collection('matches')
            .doc(matchId)
            .collection('balls')
            .get();

        int matchRuns = 0;
        int matchBalls = 0;
        int matchWickets = 0;
        int matchFours = 0;
        int matchSixes = 0;

        // Track bowling stats for this match
        int matchBallsBowled = 0;
        int matchRunsConceded = 0;
        int matchWicketsTaken = 0;
        Map<int, int> oversMap = {}; // To track maidens

        for (final ballDoc in ballsSnapshot.docs) {
          final ball = ballDoc.data();

          // Batting stats
          if (ball['batsmanUid'] == playerId) {
            final runs = (ball['runs'] ?? 0) as int;
            final isLegal = ball['extra'] == null;

            matchRuns += runs;
            totalRuns += runs;

            if (isLegal) {
              matchBalls++;
              ballsFaced++;

              if (runs == 4) {
                matchFours++;
                fours++;
              } else if (runs == 6) {
                matchSixes++;
                sixes++;
              }
            }

            // Check if out
            if (ball['isWicket'] == true) {
              timesOut++;
              if (matchRuns == 0) ducks++;
            }
          }

          // Bowling stats
          if (ball['bowlerUid'] == playerId) {
            final runs = (ball['runs'] ?? 0) as int;
            final isLegal = ball['extra'] == null;

            if (isLegal) {
              matchBallsBowled++;
              ballsBowled++;

              final over = (ball['over'] ?? 0) as int;
              oversMap[over] = (oversMap[over] ?? 0) + runs;
            }

            matchRunsConceded += runs;
            runsConceded += runs;

            if (ball['isWicket'] == true) {
              // Only count if bowler gets credit
              final bool bowlerGetsCredit = ball['bowlerGetsCredit'] ?? true;
              if (bowlerGetsCredit) {
                totalWickets++;
              }
            }
          }
        }

        // Update highest score
        if (matchRuns > highestScore) {
          highestScore = matchRuns;
        }

        // Check for milestones
        if (matchRuns >= 50 && matchRuns < 100) fifties++;
        if (matchRuns >= 100) centuries++;

        // Update best bowling
        if (matchWicketsTaken > bestWickets ||
            (matchWicketsTaken == bestWickets && matchRunsConceded < bestRuns)) {
          bestWickets = matchWicketsTaken;
          bestRuns = matchRunsConceded;
        }

        // Check for bowling milestones
        if (matchWicketsTaken >= 3) threeWickets++;
        if (matchWicketsTaken >= 5) fiveWickets++;

        // Count maiden overs
        oversMap.forEach((over, runs) {
          if (runs == 0 && matchBallsBowled >= 6) maidens++;
        });

        // Store for recent form
        recentMatches.add({
          'runs': matchRuns,
          'balls': matchBalls,
          'wickets': matchWicketsTaken,
          'timestamp': matchData['completedAt'] ?? matchData['createdAt'],
        });
      }

      // Calculate averages
      final battingAverage = timesOut > 0 ? totalRuns / timesOut : totalRuns.toDouble();
      final strikeRate = ballsFaced > 0 ? (totalRuns / ballsFaced) * 100 : 0.0;

      final bowlingAverage = totalWickets > 0 ? runsConceded / totalWickets : 0.0;
      final economy = ballsBowled > 0 ? runsConceded / (ballsBowled / 6) : 0.0;
      final strikeRateBowling = totalWickets > 0 ? ballsBowled / totalWickets : 0.0;

      final winPercentage = totalMatches > 0 ? (matchesWon / totalMatches) * 100 : 0.0;

      // Get recent form (last 5 matches)
      recentMatches.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      final recentScores = recentMatches
          .take(5)
          .map((m) => m['runs'] as int)
          .toList();

      final recentWickets = recentMatches
          .take(5)
          .map((m) => m['wickets'] as int)
          .toList();

      return PlayerStatistics(
        playerId: playerId,
        playerName: playerName,
        totalMatches: totalMatches,
        matchesWon: matchesWon,
        matchesLost: matchesLost,
        winPercentage: winPercentage,
        totalRuns: totalRuns,
        ballsFaced: ballsFaced,
        battingAverage: battingAverage,
        strikeRate: strikeRate,
        highestScore: highestScore,
        fifties: fifties,
        centuries: centuries,
        fours: fours,
        sixes: sixes,
        ducks: ducks,
        totalWickets: totalWickets,
        ballsBowled: ballsBowled,
        runsConceded: runsConceded,
        bowlingAverage: bowlingAverage,
        economy: economy,
        strikeRateBowling: strikeRateBowling,
        bestBowling: '$bestWickets/$bestRuns',
        threeWickets: threeWickets,
        fiveWickets: fiveWickets,
        maidens: maidens,
        recentScores: recentScores,
        recentWickets: recentWickets,
      );
    } catch (e) {
      rethrow;
    }
  }
}