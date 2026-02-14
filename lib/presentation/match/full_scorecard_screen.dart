import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FullScorecardScreen extends StatelessWidget {
  final String matchId;
  const FullScorecardScreen({super.key, required this.matchId});

  int _i(dynamic v) => (v ?? 0).toInt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full Scorecard')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .snapshots(),
        builder: (context, matchSnap) {
          if (!matchSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final match = matchSnap.data!.data() as Map<String, dynamic>;
          final int currentInning = _i(match['currentInning']);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .doc(matchId)
                .collection('balls')
                .orderBy('inning')
                .orderBy('ballNumber')
                .snapshots(),
            builder: (context, ballsSnap) {
              if (!ballsSnap.hasData || ballsSnap.data!.docs.isEmpty) {
                return const Center(child: Text('No data available'));
              }

              final allBalls =
              ballsSnap.data!.docs.map((e) => e.data() as Map).toList();

              final ballsInning1 =
              allBalls.where((b) => b['inning'] == 0).toList();
              final ballsInning2 =
              allBalls.where((b) => b['inning'] == 1).toList();
              final String teamAName =
                  match['teamA']['name'] ?? 'Team A';
              final String teamBName =
                  match['teamB']['name'] ?? 'Team B';

// First innings batting team
              final String firstInningsTeam =
              match['firstBattingTeam'] != null
                  ? match[match['firstBattingTeam']]['name']
                  : teamAName;

// Second innings batting team (opposite)
              final String secondInningsTeam =
              firstInningsTeam == teamAName ? teamBName : teamAName;


              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= FIRST INNINGS =================
                    if (ballsInning1.isNotEmpty) ...[
                      _inningsHeader(
                        title: '1st Innings',
                        teamName: firstInningsTeam,
                      ),

                      _sectionTitle('Batting'),
                      _battingTable(_buildBattingStats(ballsInning1)),
                      const SizedBox(height: 16),

                      _sectionTitle('Bowling'),
                      _bowlingTable(_buildBowlingStats(ballsInning1)),
                      const SizedBox(height: 16),

                      _sectionTitle('Fall of Wickets'),
                      _fowList(_buildFallOfWickets(ballsInning1)),
                      const SizedBox(height: 30),
                    ],

// ================= SECOND INNINGS =================
                    if (ballsInning2.isNotEmpty) ...[
                      _inningsHeader(
                        title: '2nd Innings',
                        teamName: secondInningsTeam,
                      ),

                      _sectionTitle('Batting'),
                      _battingTable(_buildBattingStats(ballsInning2)),
                      const SizedBox(height: 16),

                      _sectionTitle('Bowling'),
                      _bowlingTable(_buildBowlingStats(ballsInning2)),
                      const SizedBox(height: 16),

                      _sectionTitle('Fall of Wickets'),
                      _fowList(_buildFallOfWickets(ballsInning2)),
                    ],

                  ],
                ),
              );
            },
          );

        },
      ),
    );
  }
  Widget _inningsHeader({
    required String title,
    required String teamName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade200,
              Colors.blueGrey.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.sports_cricket, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title – $teamName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  /* ====================== UI HELPERS ====================== */

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /* ====================== BATTING ====================== */

  Map<String, Map<String, dynamic>> _buildBattingStats(List<Map> balls) {
    final Map<String, Map<String, dynamic>> stats = {};

    for (final b in balls) {
      final String uid = b['batsmanUid'];
      final String name = b['batsmanName'];

      stats.putIfAbsent(uid, () {
        return {
          'name': name,
          'runs': 0,
          'balls': 0,
          'fours': 0,
          'sixes': 0,
          'out': false,
        };
      });

      final bool legal = b['extra'] == null;

      stats[uid]!['runs'] += _i(b['runs']);
      if (legal) stats[uid]!['balls'] += 1;
      if (_i(b['runs']) == 4) stats[uid]!['fours'] += 1;
      if (_i(b['runs']) == 6) stats[uid]!['sixes'] += 1;
      if (b['isWicket'] == true) stats[uid]!['out'] = true;
    }

    return stats;
  }

  Widget _battingTable(Map<String, Map<String, dynamic>> stats) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
        4: FlexColumnWidth(),
        5: FlexColumnWidth(),
      },
      children: [
        _tableRow(['Batsman', 'R', 'B', '4s', '6s', 'SR'], isHeader: true),
        ...stats.values.map((s) {
          final int runs = s['runs'];
          final int balls = s['balls'];
          final double sr = balls == 0 ? 0 : (runs / balls) * 100;

          return _tableRow([
            s['name'],
            runs.toString(),
            balls.toString(),
            s['fours'].toString(),
            s['sixes'].toString(),
            sr.toStringAsFixed(1),
          ]);
        }),
      ],
    );
  }

  /* ====================== BOWLING ====================== */

  Map<String, Map<String, dynamic>> _buildBowlingStats(List<Map> balls) {
    final Map<String, Map<String, dynamic>> stats = {};

    for (final b in balls) {
      final String uid = b['bowlerUid'];
      final String name = b['bowlerName'];

      stats.putIfAbsent(uid, () {
        return {
          'name': name,
          'runs': 0,
          'balls': 0,
          'wickets': 0,
        };
      });

      stats[uid]!['runs'] += _i(b['runs']);
      if (b['extra'] == null) stats[uid]!['balls'] += 1;
      if (b['isWicket'] == true) stats[uid]!['wickets'] += 1;
    }

    return stats;
  }

  Widget _bowlingTable(Map<String, Map<String, dynamic>> stats) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
        4: FlexColumnWidth(),
      },
      children: [
        _tableRow(['Bowler', 'O', 'R', 'W', 'Econ'], isHeader: true),
        ...stats.values.map((s) {
          final int balls = s['balls'];
          final int completeOvers = balls ~/ 6;  // Complete overs
          final int remainingBalls = balls % 6;   // Remaining balls
          final String oversDisplay = '$completeOvers.$remainingBalls';  // Cricket format
          final double actualOvers = balls / 6;  // For economy calculation
          final double econ = actualOvers == 0 ? 0 : s['runs'] / actualOvers;

          return _tableRow([
            s['name'],
            oversDisplay,  // Now shows 0.4 for 4 balls, not 0.7
            s['runs'].toString(),
            s['wickets'].toString(),
            econ.toStringAsFixed(2),
          ]);
        }),
      ],
    );
  }

  /* ====================== FALL OF WICKETS ====================== */

  List<String> _buildFallOfWickets(List<Map> balls) {
    final List<String> fow = [];
    int score = 0;
    int wickets = 0;

    for (final b in balls) {
      score += _i(b['runs']);
      if (b['isWicket'] == true) {
        wickets++;
        fow.add('$score/$wickets (${b['batsmanName']})');
      }
    }

    return fow;
  }

  Widget _fowList(List<String> fow) {
    if (fow.isEmpty) return const Text('No wickets');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fow
          .map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('• $e'),
      ))
          .toList(),
    );
  }

  /* ====================== TABLE ROW ====================== */

  TableRow _tableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration:
      isHeader ? BoxDecoration(color: Colors.grey.shade200) : null,
      children: cells
          .map(
            (c) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            c,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
              isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}
