import 'package:cric_rec/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostMatchScreen extends StatefulWidget {
  const HostMatchScreen({super.key});

  @override
  State<HostMatchScreen> createState() => _HostMatchScreenState();
}

class _HostMatchScreenState extends State<HostMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matchNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _oversController = TextEditingController(text: '20');
  final _playersPerTeamController = TextEditingController(text: '11');

  String _ballType = 'Tennis';
  bool _isLoading = false;

  @override
  void dispose() {
    _matchNameController.dispose();
    _locationController.dispose();
    _oversController.dispose();
    _playersPerTeamController.dispose();
    super.dispose();
  }

  Future<void> _createMatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User not authenticated'),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    final matchesRef = FirebaseFirestore.instance.collection('matches');

    try {
      final docRef = matchesRef.doc();

      await docRef.set({
        'matchId': docRef.id,
        'hostId': uid,
        'matchName': _matchNameController.text.trim(),
        'location': _locationController.text.trim(),
        'matchType': 'Limited Overs',
        'overs': int.parse(_oversController.text),
        'ballType': _ballType,
        'playersPerTeam': int.parse(_playersPerTeamController.text),
        'status': 'created',
        'isTeamLocked': false,
        'teamA': {
          'name': 'Team A',
          'players': [],
        },
        'teamB': {
          'name': 'Team B',
          'players': [],
        },
        'currentInning': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Match created successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );

        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase error: ${e.message}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create match: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Host a Match')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _matchNameController,
                    decoration: const InputDecoration(
                      labelText: 'Match Name',
                      hintText: 'e.g., Sunday League Match',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sports_cricket),
                    ),
                    validator: _validateMatchName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location / Ground',
                      hintText: 'e.g., City Cricket Ground',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: _validateLocation,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _oversController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Overs',
                      hintText: 'Number of overs per innings',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    validator: _validateOvers,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _playersPerTeamController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Players Per Team',
                      hintText: '2 to 11 players',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    validator: _validatePlayersPerTeam,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _ballType,
                    decoration: const InputDecoration(
                      labelText: 'Ball Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sports_baseball),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tennis', child: Text('Tennis Ball')),
                      DropdownMenuItem(value: 'Leather', child: Text('Leather Ball')),
                    ],
                    onChanged: (value) => setState(() => _ballType = value!),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createMatch,
                      icon: const Icon(Icons.add_circle),
                      label: const Text(
                        'Create Match',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info card
                  Card(
                    color: AppTheme.info.withOpacity(0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.info),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'You can edit team names and add players after creating the match.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: colorScheme.scrim.withOpacity(0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: 16),
                        const Text('Creating match...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Validation functions
  String? _validateMatchName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Match name is required';
    }
    if (value.trim().length < 3) {
      return 'Match name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Match name must be less than 50 characters';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    if (value.trim().length < 3) {
      return 'Location must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Location must be less than 50 characters';
    }
    return null;
  }

  String? _validateOvers(String? value) {
    if (value == null || value.isEmpty) {
      return 'Overs is required';
    }

    final overs = int.tryParse(value);
    if (overs == null) {
      return 'Please enter a valid number';
    }
    if (overs < 1) {
      return 'Minimum 1 over required';
    }
    if (overs > 50) {
      return 'Maximum 50 overs allowed';
    }
    return null;
  }

  String? _validatePlayersPerTeam(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number of players is required';
    }

    final players = int.tryParse(value);
    if (players == null) {
      return 'Please enter a valid number';
    }
    if (players < 2) {
      return 'Minimum 2 players required';
    }
    if (players > 11) {
      return 'Maximum 11 players allowed';
    }
    return null;
  }
}