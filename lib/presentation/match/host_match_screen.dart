import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostMatchScreen extends StatefulWidget {
  const HostMatchScreen({super.key});

  @override
  State<HostMatchScreen> createState() => _HostMatchScreenState();
}

class _HostMatchScreenState extends State<HostMatchScreen> {
  final _matchNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _oversController = TextEditingController(text: '20');
  final _playersPerTeamController = TextEditingController(text: '11');

  String _ballType = 'Tennis';
  bool _isLoading = false;

  Future<void> _createMatch() async {
    if (_matchNameController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match name and location are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
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
        'status': 'scheduled',
        'teamA': {
          'name': 'Team A',
          'players': [],
        },
        'teamB': {
          'name': 'Team B',
          'players': [],
        },
        'toss': {
          'winner': null,
          'decision': null,
        },
        'currentInning': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // return to Home
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create match')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _matchNameController.dispose();
    _locationController.dispose();
    _oversController.dispose();
    _playersPerTeamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host a Match')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _matchNameController,
              decoration: const InputDecoration(labelText: 'Match Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location / Ground'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _oversController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Overs'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _playersPerTeamController,
              keyboardType: TextInputType.number,
              decoration:
              const InputDecoration(labelText: 'Players Per Team'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _ballType,
              items: const [
                DropdownMenuItem(value: 'Tennis', child: Text('Tennis')),
                DropdownMenuItem(value: 'Leather', child: Text('Leather')),
              ],
              onChanged: (value) => setState(() => _ballType = value!),
              decoration: const InputDecoration(labelText: 'Ball Type'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createMatch,
                child: const Text('Create Match'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
