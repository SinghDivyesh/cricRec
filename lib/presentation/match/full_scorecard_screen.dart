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
          // ✅ IMPROVEMENT: Better error handling
          if (matchSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (matchSnap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error loading scorecard'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (!matchSnap.hasData || matchSnap.data?.data() == null) {
            return const Center(child: Text('No match data available'));
          }

          final match = matchSnap.data!.data() as Map<String, dynamic>;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .doc(matchId)
                .collection('balls')
                .orderBy('inning')
                .orderBy('ballNumber')
                .snapshots(),
            builder: (context, ballsSnap) {
              if (!ballsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (ballsSnap.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No balls bowled yet'),
                    ],
                  ),
                );
              }

              final allBalls = ballsSnap.data!.docs
                  .map((e) => e.data() as Map<String, dynamic>)
                  .toList();

              final ballsInning1 = allBalls.where((b) => b['inning'] == 0).toList();
              final ballsInning2 = allBalls.where((b) => b['inning'] == 1).toList();

              final String teamAName = match['teamA']['name'] ?? 'Team A';
              final String teamBName = match['teamB']['name'] ?? 'Team B';

              // ✅ BUG FIX #2: Get first batting team from saved field
              final String firstInningsTeam = match['firstBattingTeam'] != null
                  ? match[match['firstBattingTeam']]['name'] ?? teamAName
                  : (match['toss']?['battingTeam'] != null
                  ? match[match['toss']['battingTeam']]['name'] ?? teamAName
                  : teamAName);

              final String secondInningsTeam = firstInningsTeam == teamAName ? teamBName : teamAName;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match Header
                    _matchHeader(match),
                    const SizedBox(height: 16),

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

                    // Match Result
                    if (match['winner'] != null) ...[
                      const SizedBox(height: 30),
                      _matchResult(match),
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

  Widget _matchHeader(Map<String, dynamic> match) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            match['matchName'] ?? 'Match',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            match['location'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchResult(Map<String, dynamic> match) {
    final String? winner = match['winner'];
    final String winnerName = match['winnerName'] ?? 'Unknown';

    if (winner == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade300, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Match Result',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$winnerName WINS!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      final String uid = b['batsmanUid'] ?? '';
      final String name = b['batsmanName'] ?? 'Unknown';

      if (uid.isEmpty) continue;

      stats.putIfAbsent(uid, () {
        return {
          'name': name,
          'runs': 0,
          'balls': 0,
          'fours': 0,
          'sixes': 0,
          'out': false,
          'dismissal': null, // ✅ NEW: Store dismissal info
        };
      });

      final bool legal = b['extra'] == null;

      stats[uid]!['runs'] += _i(b['runs']);
      if (legal) stats[uid]!['balls'] += 1;
      if (_i(b['runs']) == 4) stats[uid]!['fours'] += 1;
      if (_i(b['runs']) == 6) stats[uid]!['sixes'] += 1;

      // ✅ NEW: Store dismissal information
      if (b['isWicket'] == true) {
        stats[uid]!['out'] = true;
        stats[uid]!['dismissal'] = b['dismissalText'] ?? 'Wicket';
      }
    }

    return stats;
  }

  Widget _battingTable(Map<String, Map<String, dynamic>> stats) {
    if (stats.isEmpty) {
      return const Center(child: Text('No batting data'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 40,
        dataRowHeight: 50,
        border: TableBorder.all(color: Colors.grey.shade300),
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
        columns: const [
          DataColumn(
            label: Text(
              'Batsman',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'R',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'B',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '4s',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '6s',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'SR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: stats.values.map((s) {
          final int runs = s['runs'];
          final int balls = s['balls'];
          final double sr = balls == 0 ? 0 : (runs / balls) * 100;
          final bool isOut = s['out'] ?? false;
          final String? dismissal = s['dismissal'];

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isOut && dismissal != null)
                        Text(
                          dismissal,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (!isOut)
                        Text(
                          'not out',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(runs.toString())),
              DataCell(Text(balls.toString())),
              DataCell(Text(s['fours'].toString())),
              DataCell(Text(s['sixes'].toString())),
              DataCell(Text(sr.toStringAsFixed(1))),
            ],
          );
        }).toList(),
      ),
    );
  }

  /* ====================== BOWLING ====================== */

  Map<String, Map<String, dynamic>> _buildBowlingStats(List<Map> balls) {
    final Map<String, Map<String, dynamic>> stats = {};

    for (final b in balls) {
      final String uid = b['bowlerUid'] ?? '';
      final String name = b['bowlerName'] ?? 'Unknown';

      if (uid.isEmpty) continue;

      stats.putIfAbsent(uid, () {
        return {
          'name': name,
          'runs': 0,
          'balls': 0,
          'wickets': 0,
          'maidens': 0,
          'wides': 0,
          'noBalls': 0,
        };
      });

      stats[uid]!['runs'] += _i(b['runs']);

      if (b['extra'] == null) {
        stats[uid]!['balls'] += 1;
      } else if (b['extra'] == 'wide') {
        stats[uid]!['wides'] += 1;
      } else if (b['extra'] == 'no-ball') {
        stats[uid]!['noBalls'] += 1;
      }

      if (b['isWicket'] == true) {
        // ✅ Only count if bowler gets credit
        final bool bowlerGetsCredit = b['bowlerGetsCredit'] ?? true;
        if (bowlerGetsCredit) {
          stats[uid]!['wickets'] += 1;
        }
      }
    }

    return stats;
  }

  Widget _bowlingTable(Map<String, Map<String, dynamic>> stats) {
    if (stats.isEmpty) {
      return const Center(child: Text('No bowling data'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 40,
        dataRowHeight: 50,
        border: TableBorder.all(color: Colors.grey.shade300),
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
        columns: const [
          DataColumn(
            label: Text(
              'Bowler',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'O',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'R',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'W',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Econ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Wd',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Nb',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: stats.values.map((s) {
          final int balls = s['balls'];
          final int completeOvers = balls ~/ 6;
          final int remainingBalls = balls % 6;
          final String oversDisplay = '$completeOvers.$remainingBalls';
          final double actualOvers = balls / 6;
          final double econ = actualOvers == 0 ? 0 : s['runs'] / actualOvers;

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 120,
                  child: Text(
                    s['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(oversDisplay)),
              DataCell(Text(s['runs'].toString())),
              DataCell(Text(s['wickets'].toString())),
              DataCell(Text(econ.toStringAsFixed(2))),
              DataCell(Text(s['wides'].toString())),
              DataCell(Text(s['noBalls'].toString())),
            ],
          );
        }).toList(),
      ),
    );
  }


  /* ====================== FALL OF WICKETS ====================== */

  List<Map<String, String>> _buildFallOfWickets(List<Map> balls) {
    final List<Map<String, String>> fow = [];
    int score = 0;
    int wickets = 0;

    for (final b in balls) {
      score += _i(b['runs']);
      if (b['isWicket'] == true) {
        wickets++;
        final String dismissal = b['dismissalText'] ??
            b['batsmanName'] ??
            'Unknown';
        final int over = _i(b['over']);
        final int ballInOver = _i(b['ballInOver']);

        fow.add({
          'score': '$score/$wickets',
          'dismissal': dismissal,
          'over': '${over + 1}.$ballInOver',
        });
      }
    }

    return fow;
  }

  Widget _fowList(List<Map<String, String>> fow) {
    if (fow.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No wickets'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fow.length,
      itemBuilder: (context, index) {
        final wicket = fow[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  wicket['score']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wicket['dismissal']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Over: ${wicket['over']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  /* ====================== TABLE ROW ====================== */

  TableRow _tableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: isHeader ? BoxDecoration(color: Colors.grey.shade200) : null,
      children: cells
          .map(
            (c) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            c,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}
