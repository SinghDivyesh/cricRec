import 'package:cric_rec/core/theme/app_theme.dart';
import 'package:cric_rec/presentation/match/ball_by_ball_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InningsSetupScreen extends StatefulWidget {
  final String matchId;

  const InningsSetupScreen({super.key, required this.matchId});

  @override
  State<InningsSetupScreen> createState() => _InningsSetupScreenState();
}

class _InningsSetupScreenState extends State<InningsSetupScreen> {
  String? strikerUid;
  String? nonStrikerUid;
  String? bowlerUid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Innings Setup')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String battingTeam = data['battingTeam'];
          final String bowlingTeam = data['bowlingTeam'];

          final List batters = data[battingTeam]['players'] as List;

          final List bowlers = data[bowlingTeam]['players'] as List;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Opening Players',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                /// STRIKER
                DropdownButtonFormField<String>(
                  value: strikerUid,
                  decoration: const InputDecoration(
                    labelText: 'Striker',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_cricket),
                  ),
                  items: batters.map<DropdownMenuItem<String>>((p) {
                    return DropdownMenuItem(
                      value: p['uid'],
                      child: Text(p['name']),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      strikerUid = val;
                      if (nonStrikerUid == val) {
                        nonStrikerUid = null;
                      }
                    });
                  },
                ),

                const SizedBox(height: 12),

                /// NON STRIKER
                DropdownButtonFormField<String>(
                  value: nonStrikerUid,
                  decoration: const InputDecoration(
                    labelText: 'Non-Striker',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_cricket),
                  ),
                  items: batters
                      .where((p) => p['uid'] != strikerUid)
                      .map<DropdownMenuItem<String>>((p) {
                    return DropdownMenuItem(
                      value: p['uid'],
                      child: Text(p['name']),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      nonStrikerUid = val;
                    });
                  },
                ),

                const SizedBox(height: 24),

                /// BOWLER
                DropdownButtonFormField<String>(
                  value: bowlerUid,
                  decoration: const InputDecoration(
                    labelText: 'Opening Bowler',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_baseball),
                  ),
                  items: bowlers.map<DropdownMenuItem<String>>((p) {
                    return DropdownMenuItem(
                      value: p['uid'],
                      child: Text(p['name']),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      bowlerUid = val;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.info.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.info, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select the opening batsmen and bowler to start the innings',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                /// START INNINGS
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Start Innings',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: strikerUid != null &&
                        nonStrikerUid != null &&
                        bowlerUid != null
                        ? () => _startInnings(context, data)
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _startInnings(
      BuildContext context,
      Map<String, dynamic> data,
      ) async {
    final striker = _findPlayer(data, strikerUid!, data['battingTeam']);
    final nonStriker = _findPlayer(data, nonStrikerUid!, data['battingTeam']);
    final bowler = _findPlayer(data, bowlerUid!, data['bowlingTeam']);

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .update({
      'innings': {
        'striker': striker,
        'nonStriker': nonStriker,
        'bowler': bowler,
        'runs': 0,
        'wickets': 0,
        'overs': 0.0,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BallByBallScreen(matchId: widget.matchId),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Innings started'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Map<String, dynamic> _findPlayer(
      Map<String, dynamic> data,
      String uid,
      String teamKey,
      ) {
    return (data[teamKey]['players'] as List)
        .firstWhere((p) => p['uid'] == uid);
  }
}