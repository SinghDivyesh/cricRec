import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../match/host_match_screen.dart';
import '../match/match_details_screen.dart';
import '../match/full_scorecard_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _statusFilter = 'all'; // all, created, live, completed
  String _ballTypeFilter = 'all'; // all, Tennis, Leather
  bool _showOnlyMyMatches = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _deleteMatch(BuildContext context, String matchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match'),
        content: const Text('Are you sure you want to delete this match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match deleted successfully')),
        );
      }
    }
  }

  Future<void> _markAsCompleted(
      BuildContext context, String matchId, Map<String, dynamic> data) async {
    if (data['status'] == 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match already completed')),
      );
      return;
    }

    final teamAName = data['teamA']['name'];
    final teamBName = data['teamB']['name'];

    final winner = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: const Text('Select the winning team:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'teamA'),
            child: Text(teamAName),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'teamB'),
            child: Text(teamBName),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'tie'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Tie'),
          ),
        ],
      ),
    );

    if (winner != null) {
      final winnerName = winner == 'tie'
          ? 'Match Tied'
          : (winner == 'teamA' ? teamAName : teamBName);

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .update({
        'status': 'completed',
        'winner': winner,
        'winnerName': winnerName,
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Match completed! $winnerName')),
        );
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // My Matches Toggle
                CheckboxListTile(
                  title: const Text('Show only my matches'),
                  value: _showOnlyMyMatches,
                  onChanged: (value) {
                    setModalState(() {
                      _showOnlyMyMatches = value ?? false;
                    });
                    setState(() {
                      _showOnlyMyMatches = value ?? false;
                    });
                  },
                ),

                const Divider(),
                const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _statusFilter == 'all',
                      onSelected: (selected) {
                        setModalState(() => _statusFilter = 'all');
                        setState(() => _statusFilter = 'all');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Created'),
                      selected: _statusFilter == 'created',
                      onSelected: (selected) {
                        setModalState(() => _statusFilter = 'created');
                        setState(() => _statusFilter = 'created');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Live'),
                      selected: _statusFilter == 'live',
                      onSelected: (selected) {
                        setModalState(() => _statusFilter = 'live');
                        setState(() => _statusFilter = 'live');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Completed'),
                      selected: _statusFilter == 'completed',
                      onSelected: (selected) {
                        setModalState(() => _statusFilter = 'completed');
                        setState(() => _statusFilter = 'completed');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text('Ball Type', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _ballTypeFilter == 'all',
                      onSelected: (selected) {
                        setModalState(() => _ballTypeFilter = 'all');
                        setState(() => _ballTypeFilter = 'all');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Tennis'),
                      selected: _ballTypeFilter == 'Tennis',
                      onSelected: (selected) {
                        setModalState(() => _ballTypeFilter = 'Tennis');
                        setState(() => _ballTypeFilter = 'Tennis');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Leather'),
                      selected: _ballTypeFilter == 'Leather',
                      onSelected: (selected) {
                        setModalState(() => _ballTypeFilter = 'Leather');
                        setState(() => _ballTypeFilter = 'Leather');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _selectedIndex == 0 ? _buildAppBar() : null,
      body: _selectedIndex == 0 ? _buildHomeContent() : _buildProfileContent(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sports_cricket,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'CricRec',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.red.shade700,
            ),
            onPressed: _logout,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Column(
      children: [
        // Search Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search matches...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.green.shade700,
                  ),
                  onPressed: _showFilterBottomSheet,
                ),
              ),
            ],
          ),
        ),

        // Active Filters Display
        if (_statusFilter != 'all' ||
            _ballTypeFilter != 'all' ||
            _showOnlyMyMatches)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                if (_showOnlyMyMatches)
                  Chip(
                    label: const Text('My Matches'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _showOnlyMyMatches = false);
                    },
                  ),
                if (_statusFilter != 'all')
                  Chip(
                    label: Text('Status: $_statusFilter'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _statusFilter = 'all');
                    },
                  ),
                if (_ballTypeFilter != 'all')
                  Chip(
                    label: Text('Ball: $_ballTypeFilter'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _ballTypeFilter = 'all');
                    },
                  ),
              ],
            ),
          ),

        // Matches List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.green.shade700,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sports_cricket,
                          size: 80,
                          color: Colors.green.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No matches yet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button below to host your first match',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Apply filters
              var matches = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // Search filter
                if (_searchQuery.isNotEmpty) {
                  final matchName = (data['matchName'] ?? '').toString().toLowerCase();
                  if (!matchName.contains(_searchQuery)) {
                    return false;
                  }
                }

                // My matches filter
                if (_showOnlyMyMatches && data['hostId'] != uid) {
                  return false;
                }

                // Status filter
                if (_statusFilter != 'all' && data['status'] != _statusFilter) {
                  return false;
                }

                // Ball type filter
                if (_ballTypeFilter != 'all' && data['ballType'] != _ballTypeFilter) {
                  return false;
                }

                return true;
              }).toList();

              if (matches.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No matches found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final matchDoc = matches[index];
                  final data = matchDoc.data() as Map<String, dynamic>;
                  final matchId = matchDoc.id;
                  final isMyMatch = data['hostId'] == uid;

                  return _buildMatchCard(matchId, data, isMyMatch);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(String matchId, Map<String, dynamic> data, bool isMyMatch) {
    Color statusColor;
    IconData statusIcon;

    switch (data['status']) {
      case 'live':
        statusColor = Colors.green;
        statusIcon = Icons.play_circle_filled;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (isMyMatch) {
                  // Host can access match details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchDetailsScreen(matchId: matchId),
                    ),
                  );
                } else {
                  // Others can only view scorecard
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScorecardScreen(matchId: matchId),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Match Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sports_cricket,
                        color: Colors.green.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Match Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['matchName'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (!isMyMatch)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'View Only',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['location'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.sports_baseball,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data['ballType'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                statusIcon,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data['status'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          if (data['status'] == 'completed' && data['winnerName'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    size: 16,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Won by ${data['winnerName']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Arrow Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Only wrap with Slidable if it's user's match
    if (isMyMatch) {
      return Slidable(
        key: ValueKey(matchId),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            if (data['status'] != 'completed')
              SlidableAction(
                onPressed: (context) =>
                    _markAsCompleted(context, matchId, data),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: Icons.check_circle,
                label: 'Complete',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            if (data['status'] == 'created' || data['status'] == 'live')
              SlidableAction(
                onPressed: (context) => _deleteMatch(context, matchId),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
                borderRadius: BorderRadius.circular(16),
              ),
          ],
        ),
        child: card,
      );
    }

    return card;
  }

  Widget _buildProfileContent() {
    return const ProfileScreen();
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            // Host Match - Navigate to host screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HostMatchScreen(),
              ),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Host Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}