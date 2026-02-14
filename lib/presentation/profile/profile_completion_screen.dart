import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _nameController = TextEditingController();
  final _jerseyController = TextEditingController();

  String _playingRole = 'Batsman';
  String _battingStyle = 'Right Hand Bat';
  String _bowlingStyle = 'Right Arm Medium';

  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('players').doc(uid).set({
        'uid': uid,
        'fullName': _nameController.text.trim(),
        'playingRole': _playingRole,
        'battingStyle': _battingStyle,
        'bowlingStyle': _bowlingStyle,
        'jerseyNumber': int.tryParse(_jerseyController.text),
        'matchesPlayed': 0,
        'totalRuns': 0,
        'totalWickets': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isProfileComplete': true,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jerseyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jerseyController,
              keyboardType: TextInputType.number,
              decoration:
              const InputDecoration(labelText: 'Jersey Number (Optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _playingRole,
              items: const [
                DropdownMenuItem(value: 'Batsman', child: Text('Batsman')),
                DropdownMenuItem(value: 'Bowler', child: Text('Bowler')),
                DropdownMenuItem(
                    value: 'All-Rounder', child: Text('All-Rounder')),
                DropdownMenuItem(
                    value: 'Wicketkeeper', child: Text('Wicketkeeper')),
              ],
              onChanged: (value) => setState(() => _playingRole = value!),
              decoration: const InputDecoration(labelText: 'Playing Role'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _battingStyle,
              items: const [
                DropdownMenuItem(
                    value: 'Right Hand Bat',
                    child: Text('Right Hand Bat')),
                DropdownMenuItem(
                    value: 'Left Hand Bat', child: Text('Left Hand Bat')),
              ],
              onChanged: (value) => setState(() => _battingStyle = value!),
              decoration: const InputDecoration(labelText: 'Batting Style'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _bowlingStyle,
              items: const [
                DropdownMenuItem(
                    value: 'Right Arm Medium',
                    child: Text('Right Arm Medium')),
                DropdownMenuItem(
                    value: 'Left Arm Medium', child: Text('Left Arm Medium')),
                DropdownMenuItem(
                    value: 'Off Spin', child: Text('Off Spin')),
                DropdownMenuItem(
                    value: 'Leg Spin', child: Text('Leg Spin')),
              ],
              onChanged: (value) => setState(() => _bowlingStyle = value!),
              decoration: const InputDecoration(labelText: 'Bowling Style'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
