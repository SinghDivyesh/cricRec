import 'package:cric_rec/core/theme/app_theme.dart';
import 'package:cric_rec/presentation/home/home_screen.dart';
import 'package:cric_rec/presentation/match/full_scorecard_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/* =========================== WICKET TYPES =========================== */

enum WicketType {
  bowled,
  caught,
  lbw,
  stumped,
  runOut,
  hitWicket,
  hitBallTwice,
  obstructingField,
  timedOut,
  retired,
}

String getWicketTypeLabel(WicketType type) {
  switch (type) {
    case WicketType.bowled:
      return 'Bowled';
    case WicketType.caught:
      return 'Caught';
    case WicketType.lbw:
      return 'LBW';
    case WicketType.stumped:
      return 'Stumped';
    case WicketType.runOut:
      return 'Run Out';
    case WicketType.hitWicket:
      return 'Hit Wicket';
    case WicketType.hitBallTwice:
      return 'Hit Ball Twice';
    case WicketType.obstructingField:
      return 'Obstructing Field';
    case WicketType.timedOut:
      return 'Timed Out';
    case WicketType.retired:
      return 'Retired Hurt';
  }
}

bool doesBowlerGetCredit(WicketType type) {
  return type == WicketType.bowled ||
      type == WicketType.caught ||
      type == WicketType.lbw ||
      type == WicketType.stumped ||
      type == WicketType.hitWicket;
}

class BallByBallScreen extends StatefulWidget {
  final String matchId;
  const BallByBallScreen({super.key, required this.matchId});

  @override
  State<BallByBallScreen> createState() => _BallByBallScreenState();
}

class _BallByBallScreenState extends State<BallByBallScreen> {
  String? _lastProcessedDialogState;
  bool _isInitializing = false;

  int _i(dynamic v) => (v ?? 0).toInt();

  /* =========================== BUILD =========================== */

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Scoring')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .snapshots(),
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
                  const Text('Something went wrong'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text('No match data available'));
          }

          final matchData = snapshot.data!.data() as Map<String, dynamic>;
          final innings = Map<String, dynamic>.from(matchData['innings'] ?? {});

          if (innings.isEmpty) {
            return const Center(child: Text('Innings not initialized'));
          }

          final bool inningsCompleted = innings['isCompleted'] == true;
          final int currentInning = _i(matchData['currentInning']);
          final int inningsNumber = currentInning + 1;
          final String? winner = matchData['winner'];
          final int balls = _i(innings['balls']);

          final currentState =
              '${innings['awaitingBowler']}_${innings['awaitingBatsman']}_$balls';

          if (_lastProcessedDialogState != currentState) {
            _lastProcessedDialogState = currentState;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              if (innings['awaitingBowler'] == true) {
                _showBowlerDialog(context, matchData);
              } else if (innings['awaitingBatsman'] == true) {
                _showNewBatsmanDialog(context, matchData);
              }
            });
          }

          if (winner != null && inningsNumber == 2 && inningsCompleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showMatchResultDialog(context, matchData);
              }
            });
          }

          return SafeArea(
            top: false,
            child: Column(
              children: [
                Flexible(
                  flex: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _inningsIndicator(matchData),
                        const SizedBox(height: 8),

                        if (inningsNumber == 2) _targetDisplay(matchData),

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
                ),

                Flexible(
                  flex: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _playersRow(innings, matchData),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _ballHistory(),
                  ),
                ),

                Expanded(
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
                            inningsCompleted ||
                                (inningsNumber == 2 && winner != null),
                          ),
                          const SizedBox(height: 6),

                          _extrasRow(
                            context,
                            matchData,
                            inningsCompleted ||
                                (inningsNumber == 2 && winner != null),
                          ),
                          const SizedBox(height: 6),

                          _wicketButton(
                            context,
                            matchData,
                            inningsCompleted ||
                                (inningsNumber == 2 && winner != null),
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
    final int inningsNumber = _i(matchData['currentInning']) + 1;
    final String battingTeam = matchData['battingTeam'];
    final String teamName =
        matchData[battingTeam]['name'] ?? battingTeam.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: inningsNumber == 1
            ? AppTheme.info.withOpacity(0.2)
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_cricket,
            color: inningsNumber == 1
                ? AppTheme.info
                : Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${inningsNumber == 1 ? "1st" : "2nd"} Innings - $teamName Batting',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: inningsNumber == 1
                  ? AppTheme.info
                  : Theme.of(context).colorScheme.primary,
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
          colors: [AppTheme.warning.withOpacity(0.8), AppTheme.warning],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warning.withOpacity(0.3),
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
          Container(width: 2, height: 40, color: Colors.white38),
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
          Container(width: 2, height: 40, color: Colors.white38),
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
    final String winnerName =
        matchData[winner]?['name'] ?? winner.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.8), AppTheme.primary],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, color: AppTheme.warning, size: 40),
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
            style: const TextStyle(color: Colors.white70, fontSize: 13),
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
      final int wicketsRemaining = (totalPlayers - 1) - wickets;
      return 'Won by $wicketsRemaining wickets';
    } else {
      final int runMargin = (target - 1) - runs;
      return 'Won by $runMargin runs';
    }
  }

  Widget _scoreBoard(Map<String, dynamic> innings, int balls) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          '${_i(innings['runs'])} / ${_i(innings['wickets'])}',
          style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text('Overs: ${balls ~/ 6}.${balls % 6}', style: textTheme.bodyMedium),
      ],
    );
  }

  Widget _ballHistory() {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .snapshots(),
      builder: (context, matchSnapshot) {
        if (!matchSnapshot.hasData) {
          return const SizedBox();
        }

        final matchData = matchSnapshot.data!.data() as Map<String, dynamic>;
        final int currentInning = _i(matchData['currentInning']);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .doc(widget.matchId)
              .collection('balls')
              .where('inning', isEqualTo: currentInning)
              .orderBy('ballNumber')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No balls bowled yet',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            final Map<int, List<Map<String, dynamic>>> oversMap = {};

            for (final d in docs) {
              final data = d.data() as Map<String, dynamic>;
              final int over = _i(data['over']);

              oversMap.putIfAbsent(over, () => []);
              oversMap[over]!.add(data);
            }

            final sortedOvers = oversMap.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (docs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${sortedOvers.length} Overs Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                ...sortedOvers.map((entry) {
                  final int overNumber = entry.key;
                  final List<Map<String, dynamic>> balls = entry.value;

                  final int overRuns = balls.fold(
                    0,
                        (sum, ball) => sum + _i(ball['runs']),
                  );
                  final bool hasWicket = balls.any(
                        (ball) => ball['isWicket'] == true,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Over ${overNumber + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: hasWicket
                                    ? AppTheme.wicketRed.withOpacity(0.2)
                                    : AppTheme.info.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$overRuns runs${hasWicket ? ' + W' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: hasWicket
                                      ? AppTheme.wicketRed
                                      : AppTheme.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: balls.map((ball) {
                            final bool isWicket = ball['isWicket'] == true;
                            final String? extra = ball['extra'];
                            final int runs = _i(ball['runs']);

                            String text;
                            Color bgColor = AppTheme.info.withOpacity(0.2);
                            Color textColor = colorScheme.onSurface;

                            if (isWicket) {
                              text = 'W';
                              bgColor = AppTheme.wicketRed;
                              textColor = Colors.white;
                            } else if (extra != null) {
                              text = extra == 'wide' ? 'Wd' : 'Nb';
                              bgColor = AppTheme.extraOrange.withOpacity(0.2);
                            } else {
                              text = runs.toString();
                              if (runs == 4) {
                                bgColor = AppTheme.boundaryFour.withOpacity(0.2);
                              } else if (runs == 6) {
                                bgColor = AppTheme.boundarySix.withOpacity(0.2);
                              }
                            }

                            return Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isWicket
                                      ? AppTheme.wicketRed
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _playersRow(
      Map<String, dynamic> innings,
      Map<String, dynamic> matchData,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final striker = innings['striker'];
    final nonStriker = innings['nonStriker'];
    final bowler = innings['bowler'];

    if (striker == null || nonStriker == null || bowler == null) {
      if (!_isInitializing) {
        _isInitializing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _initializePlayers(innings, matchData);
          } catch (e) {
            debugPrint('Error initializing players: $e');
          } finally {
            if (mounted) {
              setState(() {
                _isInitializing = false;
              });
            }
          }
        });
      }

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
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

        final strikerSR = strikerBalls > 0
            ? (strikerRuns / strikerBalls) * 100
            : 0.0;
        final nonStrikerSR = nonStrikerBalls > 0
            ? (nonStrikerRuns / nonStrikerBalls) * 100
            : 0.0;

        final bowlerOvers = bowlerBalls ~/ 6;
        final bowlerBallsInOver = bowlerBalls % 6;
        final bowlerEcon = bowlerBalls > 0
            ? bowlerRuns / (bowlerBalls / 6)
            : 0.0;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 140),
          child: IntrinsicHeight(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.boundarySix.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.boundarySix.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_cricket,
                          size: 14,
                          color: AppTheme.boundarySix,
                        ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.boundarySix,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isStriker
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isStriker ? colorScheme.primary : colorScheme.outline,
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
                color: isStriker
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$runs($balls)  SR:${sr.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withOpacity(0.7),
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
          .map(
            (run) => ElevatedButton(
          onPressed: disabled
              ? null
              : () => _addBall(context, data, runs: run),
          child: Text(run.toString()),
        ),
      )
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
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.wicketRed),
      onPressed: disabled
          ? null
          : () => _addBallWithWicket(context, data, runs: 0),
    );
  }

  Widget _undoButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      icon: const Icon(Icons.undo),
      label: const Text('Undo Last Ball'),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      onPressed: _undoLastBall,
    );
  }

  // =========================== WICKET DIALOG
// PART 2 - Continued from Part 1
// This contains: Wicket Dialog, Other Dialogs, Player Init, and Core Logic

  Future<Map<String, dynamic>?> _showWicketDialog(
      BuildContext context,
      Map<String, dynamic> match,
      ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final innings = match['innings'];
    final striker = innings['striker'];
    final nonStriker = innings['nonStriker'];
    final bowler = innings['bowler'];

    WicketType? selectedType;
    String? fielder;
    bool isStrikerOut = true;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Wicket!'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select dismissal type:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _buildWicketTypeButton(
                    context,
                    'Bowled',
                    WicketType.bowled,
                    Icons.sports_cricket,
                    selectedType,
                        (type) => setDialogState(() => selectedType = type),
                  ),
                  _buildWicketTypeButton(
                    context,
                    'Caught',
                    WicketType.caught,
                    Icons.pan_tool,
                    selectedType,
                        (type) => setDialogState(() => selectedType = type),
                  ),
                  _buildWicketTypeButton(
                    context,
                    'LBW',
                    WicketType.lbw,
                    Icons.block,
                    selectedType,
                        (type) => setDialogState(() => selectedType = type),
                  ),
                  _buildWicketTypeButton(
                    context,
                    'Stumped',
                    WicketType.stumped,
                    Icons.flash_on,
                    selectedType,
                        (type) => setDialogState(() => selectedType = type),
                  ),
                  _buildWicketTypeButton(
                    context,
                    'Run Out',
                    WicketType.runOut,
                    Icons.directions_run,
                    selectedType,
                        (type) => setDialogState(() => selectedType = type),
                  ),
                  _buildWicketTypeButton(
                    context,
                    'Hit Wicket',
                    WicketType.hitWicket,
                    Icons.sports_baseball,
                    selectedType,
                        (type) => setDialogState(() => selectedType = type),
                  ),

                  if (selectedType == WicketType.caught ||
                      selectedType == WicketType.stumped ||
                      selectedType == WicketType.runOut) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    if (selectedType == WicketType.caught)
                      const Text(
                        'Caught by:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (selectedType == WicketType.stumped)
                      const Text(
                        'Stumped by (Wicket-keeper):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      const Text(
                        'Run out by:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    const SizedBox(height: 8),

                    _buildFielderInput(
                      context,
                      fielder,
                          (value) => setDialogState(() => fielder = value),
                    ),
                  ],

                  if (selectedType == WicketType.runOut) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Who is out?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text(
                              striker['name'],
                              style: const TextStyle(fontSize: 12),
                            ),
                            subtitle: const Text(
                              'Striker',
                              style: TextStyle(fontSize: 10),
                            ),
                            value: true,
                            groupValue: isStrikerOut,
                            onChanged: (value) {
                              setDialogState(() => isStrikerOut = value!);
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text(
                              nonStriker['name'],
                              style: const TextStyle(fontSize: 12),
                            ),
                            subtitle: const Text(
                              'Non-Striker',
                              style: TextStyle(fontSize: 10),
                            ),
                            value: false,
                            groupValue: isStrikerOut,
                            onChanged: (value) {
                              setDialogState(() => isStrikerOut = value!);
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (selectedType != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.wicketRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.wicketRed.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dismissal:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildDismissalText(
                              selectedType!,
                              isStrikerOut ? striker : nonStriker,
                              bowler,
                              fielder,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                key: const ValueKey('cancel_wicket_btn'),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedType == null
                    ? null
                    : () {
                  if ((selectedType == WicketType.caught ||
                      selectedType == WicketType.stumped ||
                      selectedType == WicketType.runOut) &&
                      (fielder == null || fielder!.trim().isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please enter fielder name'),
                        backgroundColor: AppTheme.warning,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, {
                    'type': selectedType,
                    'fielder': fielder?.trim(),
                    'outBatsman': isStrikerOut ? striker : nonStriker,
                    'isStrikerOut': isStrikerOut,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.wicketRed,
                ),
                child: const Text('Confirm Wicket'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWicketTypeButton(
      BuildContext context,
      String label,
      WicketType type,
      IconData icon,
      WicketType? selectedType,
      Function(WicketType) onSelect,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onSelect(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.wicketRed.withOpacity(0.1)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.wicketRed
                  : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.wicketRed
                    : colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.wicketRed
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppTheme.wicketRed, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFielderInput(
      BuildContext context,
      String? currentValue,
      Function(String) onChanged,
      ) {
    return TextFormField(
      initialValue: currentValue,
      decoration: InputDecoration(
        hintText: 'Enter fielder name',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: onChanged,
    );
  }

  String _buildDismissalText(
      WicketType type,
      Map<String, dynamic> batsman,
      Map<String, dynamic> bowler,
      String? fielder,
      ) {
    final batsmanName = batsman['name'];
    final bowlerName = bowler['name'];

    switch (type) {
      case WicketType.bowled:
        return '$batsmanName b $bowlerName';
      case WicketType.caught:
        return '$batsmanName c ${fielder ?? '?'} b $bowlerName';
      case WicketType.lbw:
        return '$batsmanName lbw b $bowlerName';
      case WicketType.stumped:
        return '$batsmanName st ${fielder ?? '?'} b $bowlerName';
      case WicketType.runOut:
        return '$batsmanName run out (${fielder ?? '?'})';
      case WicketType.hitWicket:
        return '$batsmanName hit wicket b $bowlerName';
      case WicketType.hitBallTwice:
        return '$batsmanName hit ball twice';
      case WicketType.obstructingField:
        return '$batsmanName obstructing field';
      case WicketType.timedOut:
        return '$batsmanName timed out';
      case WicketType.retired:
        return '$batsmanName retired hurt';
    }
  }

  /* =========================== OTHER DIALOGS =========================== */

  void _showMatchResultDialog(
      BuildContext context,
      Map<String, dynamic> matchData,
      ) {
    final textTheme = Theme.of(context).textTheme;
    final String? winner = matchData['winner'];
    if (winner == null) return;

    final String winnerName =
        matchData[winner]?['name'] ?? winner.toUpperCase();
    final String margin = _getWinMargin(matchData, winner);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: AppTheme.warning, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Match Finished!',
                style: textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winnerName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(margin, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewBatsmanDialog(
      BuildContext context,
      Map<String, dynamic> match,
      ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final innings = match['innings'];
    final String battingTeamKey = match['battingTeam'];

    final List players = match[battingTeamKey]['players'] ?? [];
    final List outPlayers = innings['outPlayers'] ?? [];

    final availablePlayers = players
        .where(
          (p) =>
      !outPlayers.contains(p['uid']) &&
          p['uid'] != innings['nonStriker']['uid'],
    )
        .toList();

    if (availablePlayers.isEmpty) return;

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Select New Batsman'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availablePlayers.length,
              itemBuilder: (context, index) {
                final p = availablePlayers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.sports_cricket,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text(p['name']),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
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

    _lastProcessedDialogState = null;
  }

  Future<void> _showBowlerDialog(
      BuildContext context,
      Map<String, dynamic> match,
      ) async {
    final innings = match['innings'];
    final String battingTeamKey = match['battingTeam'];
    final String bowlingTeamKey = battingTeamKey == 'teamA' ? 'teamB' : 'teamA';

    final previousBowler = innings['previousBowler'];
    final List players = match[bowlingTeamKey]['players'] ?? [];

    final selectable = players
        .where(
          (p) => previousBowler == null || p['uid'] != previousBowler['uid'],
    )
        .toList();

    if (selectable.isEmpty) return;

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Select New Bowler'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: selectable.length,
              itemBuilder: (context, index) {
                final p = selectable[index];
                return ListTile(
                  leading: const Icon(Icons.sports_cricket),
                  title: Text(p['name']),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (selected == null) return;

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .update({'innings.bowler': selected, 'innings.awaitingBowler': false});

    _lastProcessedDialogState = null;
  }

  Future<Map<String, dynamic>?> _showPlayerSelectionDialog(
      BuildContext context,
      String title,
      List players,
      String subtitle,
      ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          player['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
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

  Future<void> _startSecondInnings(Map<String, dynamic> match) async {
    final textTheme = Theme.of(context).textTheme;

    try {
      final matchRef = FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId);

      final String firstBattingTeam = match['battingTeam'];
      final String firstBowlingTeam = firstBattingTeam == 'teamA'
          ? 'teamB'
          : 'teamA';

      final int firstInningsRuns = _i(match['innings']['runs']);

      final List battingPlayers = match[firstBowlingTeam]['players'];
      final List bowlingPlayers = match[firstBattingTeam]['players'];

      if (battingPlayers.length < 2 || bowlingPlayers.isEmpty) {
        debugPrint('Not enough players to start second innings');
        return;
      }

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.flag, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'First Innings Complete!',
                    style: textTheme.titleLarge,
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
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Target: ${firstInningsRuns + 1}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warning,
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

      if (!mounted) return;

      final openingStriker = await _showPlayerSelectionDialog(
        context,
        'Select Opening Striker',
        battingPlayers,
        '${match[firstBowlingTeam]['name']} - Opening Striker',
      );

      if (openingStriker == null) return;

      final openingNonStriker = await _showPlayerSelectionDialog(
        context,
        'Select Opening Non-Striker',
        battingPlayers.where((p) => p['uid'] != openingStriker['uid']).toList(),
        '${match[firstBowlingTeam]['name']} - Opening Non-Striker',
      );

      if (openingNonStriker == null) return;

      final openingBowler = await _showPlayerSelectionDialog(
        context,
        'Select Opening Bowler',
        bowlingPlayers,
        '${match[firstBattingTeam]['name']} - Opening Bowler',
      );

      if (openingBowler == null) return;

      await matchRef.update({
        'battingTeam': firstBowlingTeam,
        'bowlingTeam': firstBattingTeam,
        'firstBattingTeam': firstBattingTeam,
        'firstInningsRuns': firstInningsRuns,
        'target': firstInningsRuns + 1,
        'currentInning': 1,
        'innings.runs': 0,
        'innings.wickets': 0,
        'innings.balls': 0,
        'innings.isCompleted': false,
        'innings.outPlayers': [],
        'innings.striker': openingStriker,
        'innings.nonStriker': openingNonStriker,
        'innings.bowler': openingBowler,
        'innings.openingStriker': openingStriker,
        'innings.openingNonStriker': openingNonStriker,
        'innings.openingBowler': openingBowler,
        'innings.awaitingBowler': false,
        'innings.awaitingBatsman': false,
        'innings.previousBowler': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Second innings started!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting second innings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /* =========================== PLAYER INITIALIZATION =========================== */

  Future<void> _initializePlayers(
      Map<String, dynamic> innings,
      Map<String, dynamic> matchData,
      ) async {
    try {
      final matchRef = FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId);

      var openingStriker = innings['openingStriker'];
      var openingNonStriker = innings['openingNonStriker'];
      var openingBowler = innings['openingBowler'];

      if (openingStriker == null ||
          openingNonStriker == null ||
          openingBowler == null) {
        final String battingTeamKey = matchData['battingTeam'];
        final String bowlingTeamKey = battingTeamKey == 'teamA'
            ? 'teamB'
            : 'teamA';

        final List battingPlayers = matchData[battingTeamKey]['players'] ?? [];
        final List bowlingPlayers = matchData[bowlingTeamKey]['players'] ?? [];

        if (battingPlayers.length >= 2 && bowlingPlayers.isNotEmpty) {
          openingStriker = openingStriker ?? battingPlayers[0];
          openingNonStriker = openingNonStriker ?? battingPlayers[1];
          openingBowler = openingBowler ?? bowlingPlayers[0];

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
        await matchRef.update({
          'innings.striker': openingStriker,
          'innings.nonStriker': openingNonStriker,
          'innings.bowler': openingBowler,
        });
      }
    } catch (e) {
      debugPrint('Error initializing players: $e');
      rethrow;
    }
  }

  /* =========================== CORE LOGIC =========================== */

  Future<void> _undoLastBall() async {
    final matchRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId);

    final matchSnap = await matchRef.get();
    if (!matchSnap.exists) return;

    final match = matchSnap.data()!;
    final int currentInning = _i(match['currentInning']);

    final ballsSnap = await matchRef
        .collection('balls')
        .where('inning', isEqualTo: currentInning)
        .orderBy('ballNumber', descending: true)
        .limit(1)
        .get();

    if (ballsSnap.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No balls to undo')),
        );
      }
      return;
    }

    final lastBallDoc = ballsSnap.docs.first;
    await lastBallDoc.reference.delete();

    final remainingBallsSnap = await matchRef
        .collection('balls')
        .where('inning', isEqualTo: currentInning)
        .orderBy('ballNumber')
        .get();

    final innings = Map<String, dynamic>.from(match['innings']);

    int runs = 0;
    int wickets = 0;
    int balls = 0;

    final Set<String> outPlayers = {};

    var striker = innings['openingStriker'];
    var nonStriker = innings['openingNonStriker'];
    var bowler = innings['openingBowler'];

    for (final doc in remainingBallsSnap.docs) {
      final b = doc.data() as Map<String, dynamic>;

      final bool legal = b['extra'] == null;
      final int ballRuns = _i(b['runs']);

      runs += ballRuns;

      if (b['isWicket'] == true) {
        wickets++;
        outPlayers.add(b['striker']['uid']);
      }

      if (legal) {
        balls++;

        if (ballRuns.isOdd) {
          final t = striker;
          striker = nonStriker;
          nonStriker = t;
        }

        if (balls % 6 == 0) {
          final t = striker;
          striker = nonStriker;
          nonStriker = t;
          bowler = b['bowler'];
        }
      }
    }

    bool awaitingBowler = false;
    bool awaitingBatsman = false;

    if (balls > 0 && balls % 6 == 0) {
      awaitingBowler = true;
    }

    if (remainingBallsSnap.docs.isNotEmpty) {
      final lastRemainingBall =
      remainingBallsSnap.docs.last.data() as Map<String, dynamic>;
      if (lastRemainingBall['isWicket'] == true) {
        awaitingBatsman = true;
      }
    }

    await matchRef.update({
      'innings.runs': runs,
      'innings.wickets': wickets,
      'innings.balls': balls,
      'innings.striker': striker,
      'innings.nonStriker': nonStriker,
      'innings.bowler': bowler,
      'innings.outPlayers': outPlayers.toList(),
      'innings.awaitingBowler': awaitingBowler,
      'innings.awaitingBatsman': awaitingBatsman,
      'innings.isCompleted': false,
      'winner': FieldValue.delete(),
      'status': 'live',
      'winnerName': FieldValue.delete(),
    });

    _lastProcessedDialogState = null;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Last ball undone')),
      );
    }
  }

  Future<void> _addBall(
      BuildContext context,
      Map<String, dynamic> match, {
        int runs = 0,
        bool isWicket = false,
        String? extra,
      }) async {
    if (isWicket) {
      await _addBallWithWicket(context, match, runs: runs, extra: extra);
      return;
    }

    final innings = Map<String, dynamic>.from(match['innings']);
    final int currentInning = _i(match['currentInning']);

    if (innings['isCompleted'] == true && currentInning == 1) {
      return;
    }

    int totalRuns = _i(innings['runs']);
    int wickets = _i(innings['wickets']);
    int balls = _i(innings['balls']);

    final int maxOvers = _i(match['overs']);
    final bool legalBall = extra == null;

    totalRuns += runs;
    if (legalBall) balls++;

    if (legalBall && runs.isOdd) {
      final t = innings['striker'];
      innings['striker'] = innings['nonStriker'];
      innings['nonStriker'] = t;
    }

    final bool overCompleted = legalBall && balls % 6 == 0;

    if (overCompleted) {
      final t = innings['striker'];
      innings['striker'] = innings['nonStriker'];
      innings['nonStriker'] = t;

      innings['awaitingBowler'] = true;
      innings['previousBowler'] = innings['bowler'];
    }

    if (legalBall || extra != null) {
      final int ballNumber = balls;
      final int over = (balls - 1) ~/ 6;
      final int ballInOver = (balls - 1) % 6 + 1;

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('balls')
          .add({
        'inning': currentInning,
        'ballNumber': ballNumber,
        'over': over,
        'ballInOver': ballInOver,
        'runs': runs,
        'extra': extra,
        'isWicket': false,
        'striker': innings['striker'],
        'bowler': innings['bowler'],
        'batsmanUid': innings['striker']['uid'],
        'batsmanName': innings['striker']['name'],
        'bowlerUid': innings['bowler']['uid'],
        'bowlerName': innings['bowler']['name'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    final String battingTeamKey = match['battingTeam'];
    final String bowlingTeamKey = battingTeamKey == 'teamA' ? 'teamB' : 'teamA';

    final int totalPlayers = (match[battingTeamKey]['players'] as List).length;

    final bool isAllOut =
        innings['outPlayers'] != null &&
            innings['outPlayers'].length >= totalPlayers - 1;

    final bool oversFinished = maxOvers > 0 && (balls ~/ 6) >= maxOvers;

    bool targetReached = false;
    String? winner;

    if (currentInning == 1) {
      final int target = _i(match['target']);

      if (totalRuns >= target) {
        targetReached = true;
        winner = battingTeamKey;
      }
    }

    final bool inningsCompleted = isAllOut || oversFinished || targetReached;

    if (inningsCompleted && currentInning == 1 && !targetReached) {
      winner = bowlingTeamKey;
    }

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
      'innings.awaitingBatsman': false,
      if (winner != null) 'winner': winner,
      if (winner != null) 'status': 'completed',
      if (winner != null) 'winnerName': match[winner]['name'],
      if (winner != null) 'completedAt': FieldValue.serverTimestamp(),
    });

    if (inningsCompleted && currentInning == 0) {
      debugPrint('First innings completed! Starting second innings...');
      await _startSecondInnings(match);
      return;
    }

    _lastProcessedDialogState = null;
  }

  Future<void> _addBallWithWicket(
      BuildContext context,
      Map<String, dynamic> match, {
        int runs = 0,
        String? extra,
      }) async {
    final wicketData = await _showWicketDialog(context, match);

    if (wicketData == null) {
      return;
    }

    final WicketType wicketType = wicketData['type'];
    final String? fielder = wicketData['fielder'];
    final Map<String, dynamic> outBatsman = wicketData['outBatsman'];
    final bool isStrikerOut = wicketData['isStrikerOut'];

    final innings = Map<String, dynamic>.from(match['innings']);
    final int currentInning = _i(match['currentInning']);

    int totalRuns = _i(innings['runs']);
    int wickets = _i(innings['wickets']);
    int balls = _i(innings['balls']);

    final int maxOvers = _i(match['overs']);
    final bool legalBall = extra == null;

    totalRuns += runs;
    if (legalBall) balls++;

    if (wicketType == WicketType.runOut) {
      if (!isStrikerOut && runs.isOdd) {
        final t = innings['striker'];
        innings['striker'] = innings['nonStriker'];
        innings['nonStriker'] = t;
      }
    } else {
      if (legalBall && runs.isOdd) {
        final t = innings['striker'];
        innings['striker'] = innings['nonStriker'];
        innings['nonStriker'] = t;
      }
    }

    final bool overCompleted = legalBall && balls % 6 == 0;

    if (overCompleted) {
      final t = innings['striker'];
      innings['striker'] = innings['nonStriker'];
      innings['nonStriker'] = t;

      innings['awaitingBowler'] = true;
      innings['previousBowler'] = innings['bowler'];
    }

    wickets++;

    final outPlayers = List.from(innings['outPlayers'] ?? []);
    outPlayers.add(outBatsman['uid']);
    innings['outPlayers'] = outPlayers;

    innings['awaitingBatsman'] = true;

    if (legalBall || extra != null) {
      final int ballNumber = balls;
      final int over = (balls - 1) ~/ 6;
      final int ballInOver = (balls - 1) % 6 + 1;

      final dismissalText = _buildDismissalText(
        wicketType,
        outBatsman,
        innings['bowler'],
        fielder,
      );

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('balls')
          .add({
        'inning': currentInning,
        'ballNumber': ballNumber,
        'over': over,
        'ballInOver': ballInOver,
        'runs': runs,
        'extra': extra,
        'isWicket': true,
        'wicketType': wicketType.toString().split('.').last,
        'dismissalText': dismissalText,
        'outBatsman': outBatsman,
        'fielder': fielder,
        'bowlerGetsCredit': doesBowlerGetCredit(wicketType),
        'striker': innings['striker'],
        'bowler': innings['bowler'],
        'batsmanUid': innings['striker']['uid'],
        'batsmanName': innings['striker']['name'],
        'bowlerUid': innings['bowler']['uid'],
        'bowlerName': innings['bowler']['name'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    final String battingTeamKey = match['battingTeam'];
    final String bowlingTeamKey = battingTeamKey == 'teamA' ? 'teamB' : 'teamA';
    final int totalPlayers = (match[battingTeamKey]['players'] as List).length;

    final bool isAllOut = outPlayers.length >= totalPlayers - 1;
    final bool oversFinished = maxOvers > 0 && (balls ~/ 6) >= maxOvers;

    bool targetReached = false;
    String? winner;

    if (currentInning == 1) {
      final int target = _i(match['target']);
      if (totalRuns >= target) {
        targetReached = true;
        winner = battingTeamKey;
      }
    }

    final bool inningsCompleted = isAllOut || oversFinished || targetReached;

    if (inningsCompleted && currentInning == 1 && !targetReached) {
      winner = bowlingTeamKey;
    }

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .update({
      'innings.runs': totalRuns,
      'innings.wickets': wickets,
      'innings.balls': balls,
      'innings.striker': innings['striker'],
      'innings.nonStriker': innings['nonStriker'],
      'innings.outPlayers': outPlayers,
      'innings.isCompleted': inningsCompleted,
      'innings.awaitingBowler': inningsCompleted ? false : overCompleted,
      'innings.awaitingBatsman': inningsCompleted ? false : true,
      if (winner != null) 'winner': winner,
      if (winner != null) 'status': 'completed',
      if (winner != null) 'winnerName': match[winner]['name'],
      if (winner != null) 'completedAt': FieldValue.serverTimestamp(),
    });

    if (inningsCompleted && currentInning == 0) {
      await _startSecondInnings(match);
      return;
    }

    _lastProcessedDialogState = null;
  }
}