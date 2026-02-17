import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int value;
  final String? photoUrl;

  LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.value,
    this.photoUrl,
  });
}

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get top run scorers
  Future<List<LeaderboardEntry>> getTopRunScorers({int limit = 10}) async {
    final Map<String, Map<String, dynamic>> playerStats = {};

    // Get all completed matches
    final matchesSnapshot = await _firestore
        .collection('matches')
        .where('status', isEqualTo: 'completed')
        .get();

    // Calculate total runs for each player
    for (final matchDoc in matchesSnapshot.docs) {
      final ballsSnapshot = await _firestore
          .collection('matches')
          .doc(matchDoc.id)
          .collection('balls')
          .get();

      for (final ballDoc in ballsSnapshot.docs) {
        final ball = ballDoc.data();
        final batsmanUid = ball['batsmanUid'] as String?;
        final batsmanName = ball['batsmanName'] as String?;
        final runs = (ball['runs'] ?? 0) as int;

        if (batsmanUid != null && batsmanName != null) {
          if (!playerStats.containsKey(batsmanUid)) {
            playerStats[batsmanUid] = {
              'name': batsmanName,
              'runs': 0,
            };
          }
          playerStats[batsmanUid]!['runs'] =
              (playerStats[batsmanUid]!['runs'] as int) + runs;
        }
      }
    }

    // Convert to list and sort
    final List<LeaderboardEntry> leaderboard = [];
    playerStats.forEach((uid, data) {
      leaderboard.add(LeaderboardEntry(
        playerId: uid,
        playerName: data['name'] as String,
        value: data['runs'] as int,
      ));
    });

    leaderboard.sort((a, b) => b.value.compareTo(a.value));
    return leaderboard.take(limit).toList();
  }

  /// Get top wicket takers
  Future<List<LeaderboardEntry>> getTopWicketTakers({int limit = 10}) async {
    final Map<String, Map<String, dynamic>> playerStats = {};

    final matchesSnapshot = await _firestore
        .collection('matches')
        .where('status', isEqualTo: 'completed')
        .get();

    for (final matchDoc in matchesSnapshot.docs) {
      final ballsSnapshot = await _firestore
          .collection('matches')
          .doc(matchDoc.id)
          .collection('balls')
          .where('isWicket', isEqualTo: true)
          .get();

      for (final ballDoc in ballsSnapshot.docs) {
        final ball = ballDoc.data();
        final bowlerUid = ball['bowlerUid'] as String?;
        final bowlerName = ball['bowlerName'] as String?;

        if (bowlerUid != null && bowlerName != null) {
          if (!playerStats.containsKey(bowlerUid)) {
            playerStats[bowlerUid] = {
              'name': bowlerName,
              'wickets': 0,
            };
          }
          playerStats[bowlerUid]!['wickets'] =
              (playerStats[bowlerUid]!['wickets'] as int) + 1;
        }
      }
    }

    final List<LeaderboardEntry> leaderboard = [];
    playerStats.forEach((uid, data) {
      leaderboard.add(LeaderboardEntry(
        playerId: uid,
        playerName: data['name'] as String,
        value: data['wickets'] as int,
      ));
    });

    leaderboard.sort((a, b) => b.value.compareTo(a.value));
    return leaderboard.take(limit).toList();
  }

  /// Get best strike rates (min 100 balls faced)
  Future<List<LeaderboardEntry>> getBestStrikeRates({int limit = 10}) async {
    final Map<String, Map<String, dynamic>> playerStats = {};

    final matchesSnapshot = await _firestore
        .collection('matches')
        .where('status', isEqualTo: 'completed')
        .get();

    for (final matchDoc in matchesSnapshot.docs) {
      final ballsSnapshot = await _firestore
          .collection('matches')
          .doc(matchDoc.id)
          .collection('balls')
          .get();

      for (final ballDoc in ballsSnapshot.docs) {
        final ball = ballDoc.data();
        final batsmanUid = ball['batsmanUid'] as String?;
        final batsmanName = ball['batsmanName'] as String?;
        final runs = (ball['runs'] ?? 0) as int;
        final isLegal = ball['extra'] == null;

        if (batsmanUid != null && batsmanName != null) {
          if (!playerStats.containsKey(batsmanUid)) {
            playerStats[batsmanUid] = {
              'name': batsmanName,
              'runs': 0,
              'balls': 0,
            };
          }
          playerStats[batsmanUid]!['runs'] =
              (playerStats[batsmanUid]!['runs'] as int) + runs;
          if (isLegal) {
            playerStats[batsmanUid]!['balls'] =
                (playerStats[batsmanUid]!['balls'] as int) + 1;
          }
        }
      }
    }

    // Calculate strike rates (min 100 balls)
    final List<LeaderboardEntry> leaderboard = [];
    playerStats.forEach((uid, data) {
      final balls = data['balls'] as int;
      if (balls >= 100) {
        final runs = data['runs'] as int;
        final sr = (runs / balls) * 100;
        leaderboard.add(LeaderboardEntry(
          playerId: uid,
          playerName: data['name'] as String,
          value: sr.round(),
        ));
      }
    });

    leaderboard.sort((a, b) => b.value.compareTo(a.value));
    return leaderboard.take(limit).toList();
  }

  /// Get best bowling economy (min 30 balls bowled)
  Future<List<LeaderboardEntry>> getBestEconomy({int limit = 10}) async {
    final Map<String, Map<String, dynamic>> playerStats = {};

    final matchesSnapshot = await _firestore
        .collection('matches')
        .where('status', isEqualTo: 'completed')
        .get();

    for (final matchDoc in matchesSnapshot.docs) {
      final ballsSnapshot = await _firestore
          .collection('matches')
          .doc(matchDoc.id)
          .collection('balls')
          .get();

      for (final ballDoc in ballsSnapshot.docs) {
        final ball = ballDoc.data();
        final bowlerUid = ball['bowlerUid'] as String?;
        final bowlerName = ball['bowlerName'] as String?;
        final runs = (ball['runs'] ?? 0) as int;
        final isLegal = ball['extra'] == null;

        if (bowlerUid != null && bowlerName != null) {
          if (!playerStats.containsKey(bowlerUid)) {
            playerStats[bowlerUid] = {
              'name': bowlerName,
              'runs': 0,
              'balls': 0,
            };
          }
          playerStats[bowlerUid]!['runs'] =
              (playerStats[bowlerUid]!['runs'] as int) + runs;
          if (isLegal) {
            playerStats[bowlerUid]!['balls'] =
                (playerStats[bowlerUid]!['balls'] as int) + 1;
          }
        }
      }
    }

    // Calculate economy (min 30 balls)
    final List<LeaderboardEntry> leaderboard = [];
    playerStats.forEach((uid, data) {
      final balls = data['balls'] as int;
      if (balls >= 30) {
        final runs = data['runs'] as int;
        final economy = runs / (balls / 6);
        leaderboard.add(LeaderboardEntry(
          playerId: uid,
          playerName: data['name'] as String,
          value: (economy * 10).round(), // Store as int (multiply by 10)
        ));
      }
    });

    leaderboard.sort((a, b) => a.value.compareTo(b.value)); // Lower is better
    return leaderboard.take(limit).toList();
  }

  /// Get most matches played
  Future<List<LeaderboardEntry>> getMostMatchesPlayed({int limit = 10}) async {
    final Map<String, Map<String, dynamic>> playerStats = {};

    final matchesSnapshot = await _firestore
        .collection('matches')
        .where('status', isEqualTo: 'completed')
        .get();

    for (final matchDoc in matchesSnapshot.docs) {
      final matchData = matchDoc.data();

      final teamA = (matchData['teamA']?['players'] ?? []) as List;
      final teamB = (matchData['teamB']?['players'] ?? []) as List;

      for (final player in [...teamA, ...teamB]) {
        final uid = player['uid'] as String?;
        final name = player['name'] as String?;

        if (uid != null && name != null) {
          if (!playerStats.containsKey(uid)) {
            playerStats[uid] = {
              'name': name,
              'matches': 0,
            };
          }
          playerStats[uid]!['matches'] =
              (playerStats[uid]!['matches'] as int) + 1;
        }
      }
    }

    final List<LeaderboardEntry> leaderboard = [];
    playerStats.forEach((uid, data) {
      leaderboard.add(LeaderboardEntry(
        playerId: uid,
        playerName: data['name'] as String,
        value: data['matches'] as int,
      ));
    });

    leaderboard.sort((a, b) => b.value.compareTo(a.value));
    return leaderboard.take(limit).toList();
  }
}