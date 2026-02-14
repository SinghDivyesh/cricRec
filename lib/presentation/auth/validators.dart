// lib/core/utils/validators.dart

class Validators {
  // ================= NAME VALIDATION =================
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (value.trim().length > 30) {
      return 'Name must be less than 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  // ================= EMAIL VALIDATION =================
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ================= PASSWORD VALIDATION =================
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ================= JERSEY NUMBER VALIDATION =================
  static String? validateJerseyNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Must be a valid number';
    }
    if (number < 0 || number > 99) {
      return 'Must be between 0 and 99';
    }
    return null;
  }

  // ================= MATCH NAME VALIDATION =================
  static String? validateMatchName(String? value) {
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

  // ================= LOCATION VALIDATION =================
  static String? validateLocation(String? value) {
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

  // ================= OVERS VALIDATION =================
  static String? validateOvers(String? value) {
    if (value == null || value.isEmpty) {
      return 'Overs is required';
    }

    final overs = int.tryParse(value);
    if (overs == null) {
      return 'Must be a valid number';
    }
    if (overs < 1) {
      return 'Minimum 1 over required';
    }
    if (overs > 50) {
      return 'Maximum 50 overs allowed';
    }
    return null;
  }

  // ================= PLAYERS PER TEAM VALIDATION =================
  static String? validatePlayersPerTeam(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number of players is required';
    }

    final players = int.tryParse(value);
    if (players == null) {
      return 'Must be a valid number';
    }
    if (players < 2) {
      return 'Minimum 2 players required';
    }
    if (players > 11) {
      return 'Maximum 11 players allowed';
    }
    return null;
  }

  // ================= PHONE NUMBER VALIDATION =================
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    // Check if it contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'Phone number can only contain digits';
    }

    // Check length (adjust based on your country)
    if (cleaned.length < 10 || cleaned.length > 15) {
      return 'Phone number must be 10-15 digits';
    }

    return null;
  }

  // ================= RUNS VALIDATION =================
  static String? validateRuns(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }

    final runs = int.tryParse(value);
    if (runs == null) {
      return 'Must be a number';
    }
    if (runs < 0) {
      return 'Cannot be negative';
    }
    return null;
  }

  // ================= WICKETS VALIDATION =================
  static String? validateWickets(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }

    final wickets = int.tryParse(value);
    if (wickets == null) {
      return 'Must be a number';
    }
    if (wickets < 0) {
      return 'Cannot be negative';
    }
    if (wickets > 10) {
      return 'Maximum 10 wickets';
    }
    return null;
  }
}
