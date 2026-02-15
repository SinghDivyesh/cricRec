import 'package:cric_rec/presentation/profile/statistics_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'leaderboards_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final email = FirebaseAuth.instance.currentUser!.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('players')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Profile not found'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data['fullName'] ?? 'Player',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Player Info Cards
                _buildInfoCard(
                  'Playing Role',
                  data['playingRole'] ?? 'Not Set',
                  Icons.sports_cricket,
                ),
                _buildInfoCard(
                  'Batting Style',
                  data['battingStyle'] ?? 'Not Set',
                  Icons.sports_baseball,
                ),
                _buildInfoCard(
                  'Bowling Style',
                  data['bowlingStyle'] ?? 'Not Set',
                  Icons.sports,
                ),
                if (data['jerseyNumber'] != null)
                  _buildInfoCard(
                    'Jersey Number',
                    data['jerseyNumber'].toString(),
                    Icons.tag,
                  ),

                const SizedBox(height: 24),

                // Statistics Section
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('matches')
                      .where('status', isEqualTo: 'completed')
                      .snapshots(),
                  builder: (context, matchSnapshot) {
                    int matchesPlayed = 0;
                    int matchesWon = 0;

                    if (matchSnapshot.hasData) {
                      for (final doc in matchSnapshot.data!.docs) {
                        final matchData = doc.data() as Map<String, dynamic>;

                        // Check if player participated
                        final teamA = matchData['teamA']['players'] as List;
                        final teamB = matchData['teamB']['players'] as List;

                        final participated = teamA.any((p) => p['uid'] == uid) ||
                            teamB.any((p) => p['uid'] == uid);

                        if (participated) {
                          matchesPlayed++;

                          // Check if won
                          final winner = matchData['winner'];
                          if (winner == 'teamA' && teamA.any((p) => p['uid'] == uid)) {
                            matchesWon++;
                          } else if (winner == 'teamB' && teamB.any((p) => p['uid'] == uid)) {
                            matchesWon++;
                          }
                        }
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Match Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Matches',
                                matchesPlayed.toString(),
                                Icons.sports_cricket,
                              ),
                              _buildStatItem(
                                'Won',
                                matchesWon.toString(),
                                Icons.emoji_events,
                              ),
                              _buildStatItem(
                                'Win Rate',
                                matchesPlayed > 0
                                    ? '${((matchesWon / matchesPlayed) * 100).toStringAsFixed(0)}%'
                                    : '0%',
                                Icons.trending_up,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Add this after the existing StreamBuilder for statistics
                const SizedBox(height: 16),

// Statistics Dashboard Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StatisticsDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('View Detailed Statistics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

// Leaderboards Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('View Leaderboards'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.green.shade700,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}