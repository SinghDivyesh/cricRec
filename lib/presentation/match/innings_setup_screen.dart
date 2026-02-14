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
    return Scaffold(
      appBar: AppBar(title: const Text('Innings Setup')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String battingTeam = data['battingTeam'];
          final String bowlingTeam = data['bowlingTeam'];

          final List batters =
          data[battingTeam]['players'] as List;

          final List bowlers =
          data[bowlingTeam]['players'] as List;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Opening Players',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                /// STRIKER
                DropdownButtonFormField<String>(
                  value: strikerUid,
                  decoration:
                  const InputDecoration(labelText: 'Striker'),
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
                  decoration:
                  const InputDecoration(labelText: 'Non-Striker'),
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
                  decoration:
                  const InputDecoration(labelText: 'Opening Bowler'),
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

                //const Spacer(flex: 20,),
                const SizedBox(height: 200,),

                /// START INNINGS
                SizedBox(

                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: strikerUid != null &&
                        nonStrikerUid != null &&
                        bowlerUid != null
                        ? () => _startInnings(context, data)
                        : null,
                    child: const Text('Start Innings'),
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
    final striker =
    _findPlayer(data, strikerUid!, data['battingTeam']);
    final nonStriker =
    _findPlayer(data, nonStrikerUid!, data['battingTeam']);
    final bowler =
    _findPlayer(data, bowlerUid!, data['bowlingTeam']);

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
      const SnackBar(content: Text('Innings started')),
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
