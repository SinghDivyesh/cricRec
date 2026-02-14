import 'package:cric_rec/presentation/home/home_screen.dart';
import 'package:cric_rec/presentation/match/full_scorecard_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BallByBallScreen extends StatefulWidget {
  final String matchId;
  const BallByBallScreen({super.key, required this.matchId});

  @override
  State<BallByBallScreen> createState() => _BallByBallScreenState();
}

class _BallByBallScreenState extends State<BallByBallScreen> {
  bool _bowlerDialogShown = false;
  bool _batsmanDialogShown = false;
  bool _isInitializing = false;

  int _i(dynamic v) => (v ?? 0).toInt(); // it is used to handle the type conversion of num(firebase) to int(flutter)

  /* =========================== BUILD =========================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Scoring')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matchData = snapshot.data!.data() as Map<String, dynamic>;
          final innings = Map<String, dynamic>.from(matchData['innings']);
          final bool inningsCompleted = innings['isCompleted'] == true;
          final int currentInning = _i(matchData['currentInning']); // 0 = 1st innings, 1 = 2nd innings
          final int inningsNumber = currentInning + 1; // Convert to 1-based for display
          final String? winner = matchData['winner'];

          final int balls = _i(innings['balls']);

          /// ✅ AUTO DIALOG HANDLING
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (innings['awaitingBowler'] == true && !_bowlerDialogShown) {
              _bowlerDialogShown = true;
              _showBowlerDialog(context, matchData);
            }

            if (innings['awaitingBatsman'] == true && !_batsmanDialogShown) {
              _batsmanDialogShown = true;
              _showNewBatsmanDialog(context, matchData);
            }

            // Show match result dialog
            if (winner != null && inningsNumber == 2 && inningsCompleted) {
              _showMatchResultDialog(context, matchData);
            }
          });

          return SafeArea(
            top: false,
            child: Column(
              children: [
                // Top section with fixed height
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Innings indicator
                      _inningsIndicator(matchData),
                      const SizedBox(height: 8),

                      // Target display for 2nd innings
                      if (inningsNumber == 2) _targetDisplay(matchData),

                      // Scoreboard and Full Scorecard button - FIXED OVERFLOW
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              flex: 2,
                              child: _scoreBoard(innings, balls),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              flex: 3,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(Icons.scoreboard, size: 18),
                                label: const Text(
                                  'Scorecard',
                                  style: TextStyle(fontSize: 13),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScorecardScreen(
                                        matchId: widget.matchId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Players row - scrollable if needed
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _playersRow(innings, matchData),
                ),
                const SizedBox(height: 8),

                // Middle expandable section - ball history
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _ballHistory(),
                  ),
                ),

                // Bottom fixed section - controls
                // Bottom controls — SCROLL SAFE
                SizedBox(
                  height: 220, // 🔥 FIXED HEIGHT — NO OVERFLOW
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (winner != null && inningsNumber == 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _winnerBanner(matchData, winner),
                            ),

                          _runButtons(
                            context,
                            matchData,
                            inningsCompleted || (inningsNumber == 2 && winner != null),
                          ),
                          const SizedBox(height: 6),

                          _extrasRow(
                            context,
                            matchData,
                            inningsCompleted || (inningsNumber == 2 && winner != null),
                          ),
                          const SizedBox(height: 6),

                          _wicketButton(
                            context,
                            matchData,
                            inningsCompleted || (inningsNumber == 2 && winner != null),
                          ),
                          const SizedBox(height: 6),

                          _undoButton(),
                        ],
                      ),
                    ),
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }

  /* =========================== UI WIDGETS =========================== */

  Widget _inningsIndicator(Map<String, dynamic> matchData) {
    final int inningsNumber = _i(matchData['inningsNumber']);
    final String battingTeam = matchData['battingTeam'];
    final String teamName = matchData[battingTeam]['name'] ?? battingTeam.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: inningsNumber == 1 ? Colors.blue.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_cricket,
            color: inningsNumber == 1 ? Colors.blue.shade700 : Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${inningsNumber == 1 ? "1st" : "2nd"} Innings - $teamName Batting',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: inningsNumber == 1 ? Colors.blue.shade700 : Colors.green.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetDisplay(Map<String, dynamic> matchData) {
    final int target = _i(matchData['target']);
    final innings = matchData['innings'];
    final int currentRuns = _i(innings['runs']);
    final int required = target - currentRuns;
    final int balls = _i(innings['balls']);
    final int maxOvers = _i(matchData['overs']);
    final int ballsRemaining = (maxOvers * 6) - balls;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Column(
              children: [
                const Text(
                  'TARGET',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  target.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            height: 40,
            color: Colors.white38,
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'REQUIRED',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  required > 0 ? required.toString() : '0',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            height: 40,
            color: Colors.white38,
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'BALLS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ballsRemaining.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _winnerBanner(Map<String, dynamic> matchData, String winner) {
    final String winnerName = matchData[winner]['name'] ?? winner.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.yellow,
            size: 40,
          ),
          const SizedBox(height: 6),
          Text(
            '$winnerName WINS!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getWinMargin(matchData, winner),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getWinMargin(Map<String, dynamic> matchData, String winner) {
    final String battingTeam = matchData['battingTeam'];
    final innings = matchData['innings'];
    final int wickets = _i(innings['wickets']);
    final int totalPlayers = (matchData[battingTeam]['players'] as List).length;
    final int target = _i(matchData['target']);
    final int runs = _i(innings['runs']);

    if (winner == battingTeam) {
      // Batting team won
      final int wicketsRemaining = (totalPlayers - 1) - wickets;
      return 'Won by $wicketsRemaining wickets';
    } else {
      // Bowling team won
      final int runMargin = (target - 1) - runs;
      return 'Won by $runMargin runs';
    }
  }

  Widget _scoreBoard(Map<String, dynamic> innings, int balls) {
    return Column(
      children: [
        Text(
          '${_i(innings['runs'])} / ${_i(innings['wickets'])}',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text('Overs: ${balls ~/ 6}.${balls % 6}'),
      ],
    );
  }

  //======================ball by ball history==========================
  Widget _ballHistory() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .snapshots(),
      builder: (context, matchSnapshot) {
        if (!matchSnapshot.hasData) {
          return const SizedBox();
        }

        final matchData =
        matchSnapshot.data!.data() as Map<String, dynamic>;
        final int currentInning = _i(matchData['currentInning']); // 0 or 1

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .doc(widget.matchId)
              .collection('balls')
              .where('inning', isEqualTo: currentInning) // 🔥 KEY FIX
              .orderBy('ballNumber')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No balls bowled yet',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            /// 🔹 Group balls by over number
            final Map<int, List<Map<String, dynamic>>> oversMap = {};

            for (final d in docs) {
              final data = d.data() as Map<String, dynamic>;
              final int over = _i(data['over']);

              oversMap.putIfAbsent(over, () => []);
              oversMap[over]!.add(data);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: oversMap.entries.map((entry) {
                final int overNumber = entry.key;
                final List<Map<String, dynamic>> balls = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🟣 OVER LABEL
                      Text(
                        'Over ${overNumber + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// 🟢 BALLS ROW
                      Wrap(
                        spacing: 8,
                        children: balls.map((ball) {
                          final bool isWicket =
                              ball['isWicket'] == true;
                          final String? extra = ball['extra'];
                          final int runs = _i(ball['runs']);

                          String text;
                          Color bgColor = Colors.blue.shade50;

                          if (isWicket) {
                            text = 'W';
                            bgColor = Colors.red.shade500;
                          } else if (extra != null) {
                            text = extra == 'wide' ? 'Wd' : 'Nb';
                            bgColor = Colors.orange.shade100;
                          } else {
                            text = runs.toString();
                          }

                          return Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }


  /// 🔒 PLAYERS ROW WITH NULL HANDLING AND STATS
  Widget _playersRow(Map<String, dynamic> innings, Map<String, dynamic> matchData) {
    final striker = innings['striker'];
    final nonStriker = innings['nonStriker'];
    final bowler = innings['bowler'];

    // If any player is null, initialize them
    if (striker == null || nonStriker == null || bowler == null) {
      if (!_isInitializing) {
        _isInitializing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializePlayers(innings, matchData);
        });
      }

      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('balls')
          .where('inning', isEqualTo: _i(matchData['currentInning']))
          .snapshots(),
      builder: (context, ballsSnapshot) {
        int strikerRuns = 0, strikerBalls = 0;
        int nonStrikerRuns = 0, nonStrikerBalls = 0;
        int bowlerRuns = 0, bowlerWickets = 0, bowlerBalls = 0;

        if (ballsSnapshot.hasData) {
          for (final doc in ballsSnapshot.data!.docs) {
            final ball = doc.data() as Map<String, dynamic>;
            final runs = _i(ball['runs']);
            final isLegal = ball['extra'] == null;

            if (ball['batsmanUid'] == striker['uid']) {
              strikerRuns += runs;
              if (isLegal) strikerBalls++;
            }

            if (ball['batsmanUid'] == nonStriker['uid']) {
              nonStrikerRuns += runs;
              if (isLegal) nonStrikerBalls++;
            }

            if (ball['bowlerUid'] == bowler['uid']) {
              bowlerRuns += runs;
              if (isLegal) bowlerBalls++;
              if (ball['isWicket'] == true) bowlerWickets++;
            }
          }
        }

        final strikerSR =
        strikerBalls > 0 ? (strikerRuns / strikerBalls) * 100 : 0.0;
        final nonStrikerSR =
        nonStrikerBalls > 0 ? (nonStrikerRuns / nonStrikerBalls) * 100 : 0.0;

        final bowlerOvers = bowlerBalls ~/ 6;
        final bowlerBallsInOver = bowlerBalls % 6;
        final bowlerEcon =
        bowlerBalls > 0 ? bowlerRuns / (bowlerBalls / 6) : 0.0;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 140), // 🔒 HARD SAFETY
          child: IntrinsicHeight(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🏏 BATSMEN ROW
                  Row(
                    children: [
                      _batsmanTile(
                        name: striker['name'],
                        runs: strikerRuns,
                        balls: strikerBalls,
                        sr: strikerSR,
                        isStriker: true,
                      ),
                      const SizedBox(width: 6),
                      _batsmanTile(
                        name: nonStriker['name'],
                        runs: nonStrikerRuns,
                        balls: nonStrikerBalls,
                        sr: nonStrikerSR,
                        isStriker: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// 🎯 BOWLER ROW
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_cricket,
                            size: 14, color: Colors.deepPurple),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            bowler['name'],
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '$bowlerOvers.$bowlerBallsInOver  $bowlerRuns-$bowlerWickets',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'E:${bowlerEcon.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _batsmanTile({
    required String name,
    required int runs,
    required int balls,
    required double sr,
    required bool isStriker,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isStriker ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isStriker ? Colors.green.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isStriker ? Colors.green.shade700 : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$runs($balls)  SR:${sr.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _runButtons(
      BuildContext context,
      Map<String, dynamic> data,
      bool disabled,
      ) {
    return Wrap(
      spacing: 12,
      children: [0, 1, 2, 3, 4, 6]
          .map((run) => ElevatedButton(
        onPressed: disabled
            ? null
            : () => _addBall(context, data, runs: run),
        child: Text(run.toString()),
      ))
          .toList(),
    );
  }

  Widget _extrasRow(
      BuildContext context,
      Map<String, dynamic> data,
      bool disabled,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton(
          onPressed: disabled
              ? null
              : () => _addBall(context, data, runs: 1, extra: 'wide'),
          child: const Text('Wide'),
        ),
        OutlinedButton(
          onPressed: disabled
              ? null
              : () => _addBall(context, data, runs: 1, extra: 'no-ball'),
          child: const Text('No Ball'),
        ),
      ],
    );
  }

  Widget _wicketButton(
      BuildContext context,
      Map<String, dynamic> data,
      bool disabled,
      ) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.close),
      label: const Text('Wicket'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: disabled
          ? null
          : () => _addBall(context, data, isWicket: true),
    );
  }

  // undo last ball widget
  Widget _undoButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.undo),
      label: const Text('Undo Last Ball'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
      ),
      onPressed: _undoLastBall,
    );
  }

  /* =========================== DIALOGS =========================== */

  void _showMatchResultDialog(BuildContext context, Map<String, dynamic> matchData) {
    final String? winner = matchData['winner'];
    if (winner == null) return;

    final String winnerName = matchData[winner]['name'] ?? winner.toUpperCase();
    final String margin = _getWinMargin(matchData, winner);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Match Finished!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$winnerName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              margin,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
             // Navigator.pop(context); // Go back to previous screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen()
                ),
              );
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /* =========================== PLAYER INITIALIZATION =========================== */

  Future<void> _initializePlayers(
      Map<String, dynamic> innings, Map<String, dynamic> matchData) async {
    try {
      final matchRef = FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId);

      // Try to get opening players
      var openingStriker = innings['openingStriker'];
      var openingNonStriker = innings['openingNonStriker'];
      var openingBowler = innings['openingBowler'];

      // If opening players not set, get from team players
      if (openingStriker == null ||
          openingNonStriker == null ||
          openingBowler == null) {
        final String battingTeamKey = matchData['battingTeam'];
        final String bowlingTeamKey =
        battingTeamKey == 'teamA' ? 'teamB' : 'teamA';

        final List battingPlayers =
            matchData[battingTeamKey]['players'] ?? [];
        final List bowlingPlayers =
            matchData[bowlingTeamKey]['players'] ?? [];

        if (battingPlayers.length >= 2 && bowlingPlayers.isNotEmpty) {
          openingStriker = openingStriker ?? battingPlayers[0];
          openingNonStriker = openingNonStriker ?? battingPlayers[1];
          openingBowler = openingBowler ?? bowlingPlayers[0];

          // Update Firestore
          await matchRef.update({
            'innings.striker': openingStriker,
            'innings.nonStriker': openingNonStriker,
            'innings.bowler': openingBowler,
            'innings.openingStriker': openingStriker,
            'innings.openingNonStriker': openingNonStriker,
            'innings.openingBowler': openingBowler,
          });
        }
      } else {
        // Just update current players from opening players
        await matchRef.update({
          'innings.striker': openingStriker,
          'innings.nonStriker': openingNonStriker,
          'innings.bowler': openingBowler,
        });
      }

      _isInitializing = false;
    } catch (e) {
      debugPrint('Error initializing players: $e');
      _isInitializing = false;
    }
  }

  /* =========================== CORE LOGIC =========================== */

  // undo last ball logic
  Future<void> _undoLastBall() async {
    final matchRef =
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId);

    final ballsSnap = await matchRef
        .collection('balls')
        .orderBy('ballNumber', descending: true)
        .limit(1)
        .get();

    if (ballsSnap.docs.isEmpty) return;

    final lastBallDoc = ballsSnap.docs.first;

    /// 1️⃣ Delete last ball
    await lastBallDoc.reference.delete();

    /// 2️⃣ Fetch remaining balls
    final remainingBallsSnap =
    await matchRef.collection('balls').orderBy('ballNumber').get();

    /// 3️⃣ Rebuild innings from scratch
    final matchSnap = await matchRef.get();
    final match = matchSnap.data()!;
    final innings = Map<String, dynamic>.from(match['innings']);

    int runs = 0;
    int wickets = 0;
    int balls = 0;

    final Set<String> outPlayers = {};

    var striker = innings['openingStriker'];
    var nonStriker = innings['openingNonStriker'];
    var bowler = innings['openingBowler'];

    for (final doc in remainingBallsSnap.docs) {
      final b = doc.data();

      final bool legal = b['extra'] == null;

      runs += _i(b['runs']);
      if (b['isWicket'] == true) {
        wickets++;
        outPlayers.add(b['striker']['uid']);
      }

      if (legal) balls++;

      if (legal && (b['runs'] ?? 0).isOdd) {
        final t = striker;
        striker = nonStriker;
        nonStriker = t;
      }

      if (legal && balls % 6 == 0) {
        final t = striker;
        striker = nonStriker;
        nonStriker = t;
        bowler = b['bowler'];
      }
    }

    /// 4️⃣ Update innings snapshot
    await matchRef.update({
      'innings.runs': runs,
      'innings.wickets': wickets,
      'innings.balls': balls,
      'innings.striker': striker,
      'innings.nonStriker': nonStriker,
      'innings.bowler': bowler,
      'innings.outPlayers': outPlayers.toList(),
      'innings.awaitingBowler': false,
      'innings.awaitingBatsman': false,
      'innings.isCompleted': false,
      'winner': FieldValue.delete(),
      'status': 'live',                     // NEW LINE
      'winnerName': FieldValue.delete(),    // NEW LINE
    });

    _bowlerDialogShown = false;
    _batsmanDialogShown = false;
  }

  Future<void> _addBall(
      BuildContext context,
      Map<String, dynamic> match, {
        int runs = 0,
        bool isWicket = false,
        String? extra,
      }) async {

    final innings = Map<String, dynamic>.from(match['innings']);
    final int currentInning = _i(match['currentInning']); // 0 or 1

    // 🔒 HARD STOP — match fully finished
    if (innings['isCompleted'] == true && currentInning == 1) {
      return;
    }

    int totalRuns = _i(innings['runs']);
    int wickets   = _i(innings['wickets']);
    int balls     = _i(innings['balls']);

    final int maxOvers = _i(match['overs']);
    final bool legalBall = extra == null;

    // ================= SCORE UPDATE =================
    totalRuns += runs;
    if (legalBall) balls++;

    // ================= STRIKE ROTATION =================
    if (legalBall && runs.isOdd) {
      final t = innings['striker'];
      innings['striker'] = innings['nonStriker'];
      innings['nonStriker'] = t;
    }

    // ================= OVER COMPLETION =================
    final bool overCompleted = legalBall && balls % 6 == 0;

    if (overCompleted) {
      final t = innings['striker'];
      innings['striker'] = innings['nonStriker'];
      innings['nonStriker'] = t;

      innings['awaitingBowler'] = true;
      innings['previousBowler'] = innings['bowler'];
    }

    // ================= WICKET =================
    if (isWicket) {
      wickets++;

      final outPlayers = List.from(innings['outPlayers'] ?? []);
      outPlayers.add(innings['striker']['uid']);
      innings['outPlayers'] = outPlayers;

      innings['awaitingBatsman'] = true;
    }

    // ================= BALL HISTORY =================
    if (legalBall || extra != null) {
      final int ballNumber = balls;
      final int over = (balls - 1) ~/ 6;
      final int ballInOver = (balls - 1) % 6 + 1;

      final int currentInning = _i(match['currentInning']); // 0 or 1

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('balls')
          .add({
        'inning': currentInning, // 🔥 THIS FIXES EVERYTHING
        'ballNumber': ballNumber,
        'over': over,
        'ballInOver': ballInOver,
        'runs': runs,
        'extra': extra,
        'isWicket': isWicket,
        'striker': innings['striker'],
        'bowler': innings['bowler'],
        'batsmanUid': innings['striker']['uid'],
        'batsmanName': innings['striker']['name'],
        'bowlerUid': innings['bowler']['uid'],
        'bowlerName': innings['bowler']['name'],
        'timestamp': FieldValue.serverTimestamp(),
      });

    }

    // ================= INNINGS END CHECK =================
    final String battingTeamKey = match['battingTeam'];
    final String bowlingTeamKey =
    battingTeamKey == 'teamA' ? 'teamB' : 'teamA';

    final int totalPlayers =
        (match[battingTeamKey]['players'] as List).length;

    final bool isAllOut =
        innings['outPlayers'] != null &&
            innings['outPlayers'].length >= totalPlayers - 1;

    final bool oversFinished =
        maxOvers > 0 && (balls ~/ 6) >= maxOvers;

    bool targetReached = false;
    String? winner;

    // ================= TARGET CHASE (2nd INNINGS) =================
    if (currentInning == 1) { // 2nd innings (currentInning = 1)
      final int target = _i(match['target']);

      if (totalRuns >= target) {
        targetReached = true;
        winner = battingTeamKey;
      }
    }

    final bool inningsCompleted =
        isAllOut || oversFinished || targetReached;

    // ================= DECIDE WINNER (DEFENDING TEAM) =================
    if (inningsCompleted &&
        currentInning == 1 && // 2nd innings
        !targetReached) {
      winner = bowlingTeamKey;
    }

    // ================= FIRESTORE UPDATE =================
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .update({
      'innings.runs': totalRuns,
      'innings.wickets': wickets,
      'innings.balls': balls,
      'innings.striker': innings['striker'],
      'innings.nonStriker': innings['nonStriker'],
      'innings.outPlayers': innings['outPlayers'] ?? [],
      'innings.isCompleted': inningsCompleted,
      'innings.awaitingBowler': inningsCompleted ? false : overCompleted,
      'innings.awaitingBatsman': inningsCompleted ? false : isWicket,
      if (winner != null) 'winner': winner,
      if (winner != null) 'status': 'completed',                    // NEW LINE
      if (winner != null) 'winnerName': match[winner]['name'],      // NEW LINE
      if (winner != null) 'completedAt': FieldValue.serverTimestamp(),  // NEW LINE
    });

    // ================= START SECOND INNINGS =================
    if (inningsCompleted && currentInning == 0) { // End of 1st innings
      debugPrint('First innings completed! Starting second innings...');
      debugPrint('All Out: $isAllOut, Overs Finished: $oversFinished');
      await _startSecondInnings(match);
      return;
    }

    _bowlerDialogShown = false;
    _batsmanDialogShown = false;
  }

  /* =========================== NEW BATSMAN =========================== */

  Future<void> _showNewBatsmanDialog(
      BuildContext context, Map<String, dynamic> match) async {
    final innings = match['innings'];
    final String battingTeamKey = match['battingTeam'];

    final List players = match[battingTeamKey]['players'] ?? [];

    final List outPlayers = innings['outPlayers'] ?? [];

    final availablePlayers = players
        .where((p) =>
    !outPlayers.contains(p['uid']) &&
        p['uid'] != innings['nonStriker']['uid'])
        .toList();

    if (availablePlayers.isEmpty) return;

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Select New Batsman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availablePlayers
              .map((p) => ListTile(
            title: Text(p['name']),
            onTap: () => Navigator.pop(context, p),
          ))
              .toList(),
        ),
      ),
    );

    if (selected == null) return;

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .update({
      'innings.striker': selected,
      'innings.awaitingBatsman': false,
    });

    _batsmanDialogShown = false;
  }

  // the second inning logic
  // the second inning logic
  Future<void> _startSecondInnings(Map<String, dynamic> match) async {
    try {
      final matchRef =
      FirebaseFirestore.instance.collection('matches').doc(widget.matchId);

      final String firstBattingTeam = match['battingTeam'];
      final String firstBowlingTeam =
      firstBattingTeam == 'teamA' ? 'teamB' : 'teamA';

      final int firstInningsRuns =
      (match['innings']['runs'] ?? 0).toInt();

      final List battingPlayers =
      match[firstBowlingTeam]['players'];
      final List bowlingPlayers =
      match[firstBattingTeam]['players'];

      if (battingPlayers.length < 2 || bowlingPlayers.isEmpty) {
        debugPrint('Not enough players to start second innings');
        return;
      }

      debugPrint('Starting second innings...');
      debugPrint('First innings runs: $firstInningsRuns');
      debugPrint('Target: ${firstInningsRuns + 1}');

      // Show transition dialog first
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.flag, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'First Innings Complete!',
                    style: Theme.of(dialogContext).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${match[firstBattingTeam]['name'] ?? firstBattingTeam.toUpperCase()}: $firstInningsRuns',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Target: ${firstInningsRuns + 1}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${match[firstBowlingTeam]['name'] ?? firstBowlingTeam.toUpperCase()} needs ${firstInningsRuns + 1} runs to win',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }

      // Now let user select opening batsmen and bowler
      if (!mounted) return;

      // Select Opening Striker
      final openingStriker = await _showPlayerSelectionDialog(
        context,
        'Select Opening Striker',
        battingPlayers,
        '${match[firstBowlingTeam]['name']} - Opening Striker',
      );

      if (openingStriker == null) return;

      // Select Opening Non-Striker (exclude the striker)
      final openingNonStriker = await _showPlayerSelectionDialog(
        context,
        'Select Opening Non-Striker',
        battingPlayers.where((p) => p['uid'] != openingStriker['uid']).toList(),
        '${match[firstBowlingTeam]['name']} - Opening Non-Striker',
      );

      if (openingNonStriker == null) return;

      // Select Opening Bowler
      final openingBowler = await _showPlayerSelectionDialog(
        context,
        'Select Opening Bowler',
        bowlingPlayers,
        '${match[firstBattingTeam]['name']} - Opening Bowler',
      );

      if (openingBowler == null) return;

      // Update Firestore with user-selected players
      await matchRef.update({
        // 🔁 Swap teams
        'battingTeam': firstBowlingTeam,

        // 🧮 Set target
        'target': firstInningsRuns + 1,

        // 🔢 Move to second innings (currentInning = 1 means 2nd innings)
        'currentInning': 1,

        // 🔄 Reset innings
        'innings.runs': 0,
        'innings.wickets': 0,
        'innings.balls': 0,
        'innings.isCompleted': false,
        'innings.outPlayers': [],

        // 👥 User-selected opening players
        'innings.striker': openingStriker,
        'innings.nonStriker': openingNonStriker,
        'innings.bowler': openingBowler,

        'innings.openingStriker': openingStriker,
        'innings.openingNonStriker': openingNonStriker,
        'innings.openingBowler': openingBowler,

        // 🧹 Reset flags
        'innings.awaitingBowler': false,
        'innings.awaitingBatsman': false,
        'innings.previousBowler': null,
      });

      debugPrint('Second innings started successfully with user-selected players');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Second innings started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting second innings: $e');
    }
  }

  /* =========================== BOWLER =========================== */

  Future<void> _showBowlerDialog(
      BuildContext context, Map<String, dynamic> match) async {
    final innings = match['innings'];
    final String battingTeamKey = match['battingTeam'];
    final String bowlingTeamKey =
    battingTeamKey == 'teamA' ? 'teamB' : 'teamA';

    final previousBowler = innings['previousBowler'];
    final List players = match[bowlingTeamKey]['players'] ?? [];

    final selectable = players
        .where((p) =>
    previousBowler == null || p['uid'] != previousBowler['uid'])
        .toList();

    if (selectable.isEmpty) return;

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Select New Bowler'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            shrinkWrap: true,
            children: players
                .where((p) =>
            previousBowler == null ||
                p['uid'] != previousBowler['uid'])
                .map<Widget>((p) => ListTile(
              leading: const Icon(Icons.sports_cricket),
              title: Text(p['name']),
              onTap: () => Navigator.pop(context, p),
            ))
                .toList(),
          ),
        ),
      ),
    );

    if (selected == null) return;

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .update({
      'innings.bowler': selected,
      'innings.awaitingBowler': false,
    });

    _bowlerDialogShown = false;
  }
  // Helper method to show player selection dialog
  Future<Map<String, dynamic>?> _showPlayerSelectionDialog(
      BuildContext context,
      String title,
      List players,
      String subtitle,
      ) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            Icons.person,
                            color: Colors.green.shade700,
                          ),
                        ),
                        title: Text(
                          player['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pop(dialogContext, player),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}