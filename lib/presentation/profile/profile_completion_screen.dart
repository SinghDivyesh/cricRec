import 'package:cric_rec/core/theme/app_theme.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _jerseyController = TextEditingController();

  String _playingRole = 'Batsman';
  String _battingStyle = 'Right Hand Bat';
  String _bowlingStyle = 'Right Arm Medium';

  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
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
  void dispose() {
    _nameController.dispose();
    _jerseyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Setup Your Cricket Profile',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your profile to start playing matches',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Jersey Number
                  TextFormField(
                    controller: _jerseyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jersey Number',
                      hintText: 'Optional (1-99)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final number = int.tryParse(value);
                        if (number == null) {
                          return 'Please enter a valid number';
                        }
                        if (number < 1 || number > 99) {
                          return 'Jersey number must be between 1-99';
                        }
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Playing Role
                  DropdownButtonFormField<String>(
                    value: _playingRole,
                    decoration: const InputDecoration(
                      labelText: 'Playing Role',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sports_cricket),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Batsman',
                        child: Text('Batsman'),
                      ),
                      DropdownMenuItem(
                        value: 'Bowler',
                        child: Text('Bowler'),
                      ),
                      DropdownMenuItem(
                        value: 'All-rounder',
                        child: Text('All-rounder'),
                      ),
                      DropdownMenuItem(
                        value: 'Wicketkeeper',
                        child: Text('Wicketkeeper'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _playingRole = value!),
                  ),
                  const SizedBox(height: 16),

                  // Batting Style
                  DropdownButtonFormField<String>(
                    value: _battingStyle,
                    decoration: const InputDecoration(
                      labelText: 'Batting Style',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sports),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Right Hand Bat',
                        child: Text('Right Hand Bat'),
                      ),
                      DropdownMenuItem(
                        value: 'Left Hand Bat',
                        child: Text('Left Hand Bat'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _battingStyle = value!),
                  ),
                  const SizedBox(height: 16),

                  // Bowling Style
                  DropdownButtonFormField<String>(
                    value: _bowlingStyle,
                    decoration: const InputDecoration(
                      labelText: 'Bowling Style',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sports_baseball),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Right Arm Medium',
                        child: Text('Right Arm Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'Left Arm Medium',
                        child: Text('Left Arm Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'Right Arm Fast',
                        child: Text('Right Arm Fast'),
                      ),
                      DropdownMenuItem(
                        value: 'Left Arm Fast',
                        child: Text('Left Arm Fast'),
                      ),
                      DropdownMenuItem(
                        value: 'Off Spin',
                        child: Text('Off Spin'),
                      ),
                      DropdownMenuItem(
                        value: 'Leg Spin',
                        child: Text('Leg Spin'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _bowlingStyle = value!),
                  ),
                  const SizedBox(height: 24),

                  // Info Card
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
                            'You can update your profile anytime from the settings.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveProfile,
                      icon: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _isLoading ? 'Saving...' : 'Save Profile',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        const Text('Saving your profile...'),
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
}