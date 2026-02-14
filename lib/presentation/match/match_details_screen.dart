import 'package:cric_rec/presentation/match/full_scorecard_screen.dart';
import 'package:cric_rec/presentation/match/innings_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchDetailsScreen extends StatelessWidget {
  final String matchId;

  const MatchDetailsScreen({super.key, required this.matchId});

  /* ===================== EDIT TEAM NAME ===================== */
  Future<void> _editTeamName(
      BuildContext context,
      String teamKey,
      String currentName,
      bool isLocked,
      ) async {
    if (isLocked) return;

    final controller = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Team Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter team name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('matches')
                  .doc(matchId)
                  .update({
                '$teamKey.name': newName,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /* ===================== ADD / REMOVE PLAYERS ===================== */
  Future<void> _addPlayersToTeam(
      BuildContext context,
      String teamKey,
      List currentPlayers,
      List opponentPlayers,
      int maxPlayers,
      bool isLocked,
      ) async {
    if (isLocked) return;

    final playersSnapshot =
    await FirebaseFirestore.instance.collection('players').get();

    final Set<String> selectedUids =
    currentPlayers.map((p) => p['uid'] as String).toSet();

    final Set<String> opponentUids =
    opponentPlayers.map((p) => p['uid'] as String).toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return _PlayerSelectionBottomSheet(
          playersSnapshot: playersSnapshot,
          selectedUids: selectedUids,
          opponentUids: opponentUids,
          maxPlayers: maxPlayers,
          matchId: matchId,
          teamKey: teamKey,
        );
      },
    );
  }

  /* ===================== LOCK / UNLOCK TEAMS ===================== */
  Future<void> _lockTeams(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .update({
      'isTeamLocked': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teams locked')),
    );
  }

  Future<void> _unlockTeams(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .update({
      'isTeamLocked': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teams unlocked')),
    );
  }

  /* ===================== TOSS ===================== */
  Future<void> _showTossDialog(
      BuildContext context,
      Map<String, dynamic> data,
      ) async {
    final int required = data['playersPerTeam'];
    final int teamACount = (data['teamA']['players'] as List).length;
    final int teamBCount = (data['teamB']['players'] as List).length;

    final bool areTeamsFull =
        teamACount == required && teamBCount == required;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start Match'),
        content: areTeamsFull
            ? const Text('Select batting team')
            : Text(
          'Both teams must have $required players.\n\n'
              'Team A: $teamACount / $required\n'
              'Team B: $teamBCount / $required',
        ),
        actions: areTeamsFull
            ? [
          TextButton(
            onPressed: () => _saveTossResult(context, 'teamA'),
            child: Text('${data['teamA']['name']} Bat'),
          ),
          TextButton(
            onPressed: () => _saveTossResult(context, 'teamB'),
            child: Text('${data['teamB']['name']} Bat'),
          ),
        ]
            : [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTossResult(
      BuildContext context,
      String battingTeam,
      ) async {
    final bowlingTeam =
    battingTeam == 'teamA' ? 'teamB' : 'teamA';

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .update({
      'toss': {
        'battingTeam': battingTeam,
        'bowlingTeam': bowlingTeam,
      },
      'currentInnings': 1,
      'battingTeam': battingTeam,
      'bowlingTeam': bowlingTeam,
      'status': 'live',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Match started')),
    );
  }

  Future<void> _undoToss(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .update({
      'toss': FieldValue.delete(),
      'battingTeam': FieldValue.delete(),
      'bowlingTeam': FieldValue.delete(),
      'currentInnings': FieldValue.delete(),
      'status': 'created',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toss undone')),
    );
  }

  /* ===================== UI ===================== */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          final bool isTeamLocked =
              data['isTeamLocked'] == true;

          final bool isTossDone = data['toss'] != null;

          final teamAPlayers = data['teamA']['players'] as List;
          final teamBPlayers = data['teamB']['players'] as List;
          final int requiredPlayers = data['playersPerTeam'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                data['matchName'],
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text('Location: ${data['location']}'),
              Text('Overs: ${data['overs']}'),
              Text('Ball Type: ${data['ballType']}'),
              Text('Status: ${data['status']}'),

              const Divider(height: 32),

              const Text(
                'Teams',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),

              Card(
                child: ListTile(
                  title: Text(data['teamA']['name']),
                  subtitle: Text(
                      'Players: ${teamAPlayers.length} / $requiredPlayers'),
                  trailing:
                  Icon(isTeamLocked ? Icons.lock : Icons.edit),
                  onTap: () => _editTeamName(
                    context,
                    'teamA',
                    data['teamA']['name'],
                    isTeamLocked,
                  ),
                  onLongPress: () => _addPlayersToTeam(
                    context,
                    'teamA',
                    teamAPlayers,
                    teamBPlayers,
                    requiredPlayers,
                    isTeamLocked,
                  ),
                ),
              ),

              Card(
                child: ListTile(
                  title: Text(data['teamB']['name']),
                  subtitle: Text(
                      'Players: ${teamBPlayers.length} / $requiredPlayers'),
                  trailing:
                  Icon(isTeamLocked ? Icons.lock : Icons.edit),
                  onTap: () => _editTeamName(
                    context,
                    'teamB',
                    data['teamB']['name'],
                    isTeamLocked,
                  ),
                  onLongPress: () => _addPlayersToTeam(
                    context,
                    'teamB',
                    teamBPlayers,
                    teamAPlayers,
                    requiredPlayers,
                    isTeamLocked,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (!isTeamLocked)
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text('Lock Teams'),
                  onPressed:
                  teamAPlayers.length == requiredPlayers &&
                      teamBPlayers.length == requiredPlayers
                      ? () => _lockTeams(context)
                      : null,
                ),

              if (isTeamLocked && !isTossDone)
                TextButton.icon(
                  icon: const Icon(Icons.undo),
                  label: const Text('Unlock Teams'),
                  onPressed: () => _unlockTeams(context),
                ),

              ElevatedButton.icon(
                icon: const Icon(Icons.sports_cricket),
                label: const Text('Start Match (Toss)'),
                onPressed:
                (!isTossDone && isTeamLocked)
                    ? () => _showTossDialog(context, data)
                    : null,
              ),

              if (isTossDone && data['status'] != 'completed')  // ADDED CONDITION
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${data['toss']['battingTeam'] == 'teamA'
                            ? data['teamA']['name']
                            : data['teamB']['name']} is batting first',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo Toss'),
                      onPressed: () => _undoToss(context),
                    ),
                    TextButton.icon(
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InningsSetupScreen(matchId: matchId),
                          ),
                        );
                      },
                      label: const Text('Proceed to Inning setup'),
                    )
                  ],
                ),

// ADD THIS NEW SECTION RIGHT AFTER THE ABOVE CODE:
              if (data['status'] == 'completed' && data['winner'] != null)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.yellow,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['winnerName'] != null
                                ? '${data['winnerName']} WINS!'
                                : 'Match Completed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScorecardScreen(
                                    matchId: matchId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.scoreboard),
                            label: const Text('View Full Scorecard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/* ===================== PLAYER SELECTION BOTTOM SHEET ===================== */
class _PlayerSelectionBottomSheet extends StatefulWidget {
  final QuerySnapshot playersSnapshot;
  final Set<String> selectedUids;
  final Set<String> opponentUids;
  final int maxPlayers;
  final String matchId;
  final String teamKey;

  const _PlayerSelectionBottomSheet({
    required this.playersSnapshot,
    required this.selectedUids,
    required this.opponentUids,
    required this.maxPlayers,
    required this.matchId,
    required this.teamKey,
  });

  @override
  State<_PlayerSelectionBottomSheet> createState() =>
      _PlayerSelectionBottomSheetState();
}

class _PlayerSelectionBottomSheetState
    extends State<_PlayerSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRole;
  String? _selectedBattingStyle;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _getFilteredPlayers() {
    return widget.playersSnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['fullName'] ?? '').toString().toLowerCase();
      final playingRole = data['playingRole']?.toString() ?? '';
      final battingStyle = data['battingStyle']?.toString() ?? '';

      // Search filter
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Playing role filter
      if (_selectedRole != null && playingRole != _selectedRole) {
        return false;
      }

      // Batting style filter
      if (_selectedBattingStyle != null && battingStyle != _selectedBattingStyle) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlayers = _getFilteredPlayers();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Text(
                'Add Players',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search players...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Playing Role Filter
                    ChoiceChip(
                      label: const Text('All Roles'),
                      selected: _selectedRole == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRole = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Batsman'),
                      selected: _selectedRole == 'Batsman',
                      onSelected: (selected) {
                        setState(() {
                          _selectedRole = selected ? 'Batsman' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Bowler'),
                      selected: _selectedRole == 'Bowler',
                      onSelected: (selected) {
                        setState(() {
                          _selectedRole = selected ? 'Bowler' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All-rounder'),
                      selected: _selectedRole == 'All-rounder',
                      onSelected: (selected) {
                        setState(() {
                          _selectedRole = selected ? 'All-rounder' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('|'),
                    const SizedBox(width: 8),
                    // Batting Style Filter
                    ChoiceChip(
                      label: const Text('Left Hand'),
                      selected: _selectedBattingStyle == 'Left Hand Bat',
                      onSelected: (selected) {
                        setState(() {
                          _selectedBattingStyle = selected ? 'Left Hand Bat' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Right Hand'),
                      selected: _selectedBattingStyle == 'Right Hand Bat',
                      onSelected: (selected) {
                        setState(() {
                          _selectedBattingStyle = selected ? 'Right Hand Bat' : null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Selected count
              Text(
                '${widget.selectedUids.length} / ${widget.maxPlayers} players selected',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // Players List
              Expanded(
                child: filteredPlayers.isEmpty
                    ? const Center(
                  child: Text('No players found'),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final doc = filteredPlayers[index];
                    final uid = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['fullName'] ?? 'Unnamed Player').toString();
                    final playingRole = data['playingRole']?.toString() ?? 'N/A';
                    final battingStyle = data['battingStyle']?.toString() ?? 'N/A';

                    final bool isSelected = widget.selectedUids.contains(uid);
                    final bool isBlocked =
                        widget.opponentUids.contains(uid) && !isSelected;

                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(
                        name,
                        style: TextStyle(
                          decoration: isBlocked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isBlocked ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text(
                        '$playingRole • $battingStyle',
                        style: TextStyle(
                          color: isBlocked ? Colors.grey : null,
                        ),
                      ),
                      onChanged: isBlocked
                          ? null
                          : (checked) {
                        setState(() {
                          if (checked == true) {
                            if (widget.selectedUids.length < widget.maxPlayers) {
                              widget.selectedUids.add(uid);
                            }
                          } else {
                            widget.selectedUids.remove(uid);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              // Save Button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final updatedPlayers = widget.playersSnapshot.docs
                        .where((doc) => widget.selectedUids.contains(doc.id))
                        .map((doc) => {
                      'uid': doc.id,
                      'name': doc['fullName'],
                    })
                        .toList();

                    await FirebaseFirestore.instance
                        .collection('matches')
                        .doc(widget.matchId)
                        .update({
                      '${widget.teamKey}.players': updatedPlayers,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Save Players'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}