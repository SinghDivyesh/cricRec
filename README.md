# 🏏 CricRec - Cricket Recording & Statistics Management System

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A comprehensive mobile application for cricket match management, real-time scoring, and player statistics tracking**

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Usage](#-usage) • [Tech Stack](#-tech-stack) • [Contributing](#-contributing)

</div>

---

## 📖 About The Project

CricRec is a modern, feature-rich cricket management application designed to revolutionize how cricket matches are recorded, managed, and analyzed at grassroots and amateur levels. Built with Flutter and Firebase, it provides professional-grade scoring capabilities to everyone, from local cricket clubs to individual enthusiasts.

### 🎯 Problem Statement

Traditional cricket scoring at amateur levels faces several challenges:
- Manual scorekeeping is error-prone and time-consuming
- Lack of centralized platform for player statistics
- Difficulty maintaining historical records
- No standardized system for performance comparison
- Limited accessibility to match data

### 💡 Solution

CricRec digitizes the entire cricket match ecosystem by providing:
- **Real-time ball-by-ball scoring** with automatic calculations
- **Comprehensive player profiles** with career statistics
- **Cloud-based storage** ensuring data is never lost
- **Player discovery** through search functionality
- **Match history** with complete scorecards
- **Performance analytics** with leaderboards

---

## ✨ Features

### 🔐 Authentication & User Management
- Secure email/password registration with Firebase Authentication
- Email verification for account security
- Complete player profile creation (role, batting/bowling styles, jersey number)
- Profile editing and account deletion with confirmation

### 🏏 Match Management
- Create matches with customizable settings:
  - Match name and location
  - Number of overs (1-50)
  - Ball type (Tennis/Leather)
- Team setup with player selection from registered users
- Toss management with batting decision
- Opening players selection (batsmen and bowler)
- Match filtering by status and ball type

### 📊 Live Scoring System
- **Ball-by-ball scoring** with run buttons (0, 1, 2, 3, 4, 6)
- **Extra handling** (Wide, No-ball) with automatic run addition
- **Comprehensive wicket recording**:
  - Multiple dismissal types (Bowled, Caught, LBW, Stumped, Run Out, Hit Wicket, etc.)
  - Fielder name capture for relevant dismissals
  - Batsman selection for run-outs
- **Automatic strike rotation** after odd runs
- **Over completion** with bowler change prompts
- **Innings tracking** with completion conditions
- **Undo functionality** for error correction
- **Real-time synchronization** across devices

### 📈 Statistics & Analytics
- **Batting Statistics**:
  - Runs, Balls faced, 4s, 6s
  - Strike Rate calculation
  - Highest Score tracking
- **Bowling Statistics**:
  - Overs bowled, Wickets taken
  - Runs conceded, Economy Rate
  - Best bowling figures
- **Career Statistics** across all matches
- **Milestone Tracking**:
  - Centuries (100+ runs)
  - Half-centuries (50+ runs)
  - Five-wicket hauls
- **Leaderboards** across multiple categories
- **Statistics Dashboard** with detailed analytics

### 🔍 Player Discovery
- **Search Players** by name with real-time filtering
- View comprehensive player statistics
- Player cards with key performance metrics
- Playing styles and career highlights

### 📜 Match History
- Complete archive of played matches
- **Win/Loss/Tie indicators** with color coding
- Match details (teams, location, ball type)
- Access to full scorecards from history
- Filtered view (only shows user's matches)

### 🎨 User Experience
- **Dark/Light Theme** support
- **Material Design 3** UI components
- **Bottom Navigation** with 5 tabs:
  - Home (Matches)
  - Search (Players)
  - Host (Create Match)
  - History (Past Matches)
  - Profile (User Settings)
- Responsive design for all screen sizes
- Intuitive interface with minimal learning curve

---

## 📱 Screenshots

### Authentication Flow
| Login | Registration | Profile Setup |
|-------|-------------|---------------|
| *Login Screen* | *Sign Up Screen* | *Complete Profile* |

### Match Management
| Host Match | Team Setup | Toss |
|------------|-----------|------|
| *Create Match* | *Add Players* | *Conduct Toss* |

### Live Scoring
| Ball-by-Ball | Wicket Dialog | Scorecard |
|-------------|---------------|-----------|
| *Live Scoring* | *Record Wicket* | *Full Scorecard* |

### Statistics & More
| Search Players | Match History | Leaderboards |
|---------------|---------------|--------------|
| *Player Search* | *Past Matches* | *Top Performers* |

---

## 🛠 Tech Stack

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **UI**: Material Design 3
- **State Management**: StatefulWidget + setState()
- **Real-time Updates**: StreamBuilder

### Backend
- **Platform**: Firebase (Google Cloud)
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore (NoSQL)
- **Storage**: Firebase Cloud Storage
- **Functions**: Cloud Functions (Node.js)
- **Hosting**: Firebase Hosting

### Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  provider: ^6.1.0
  flutter_slidable: ^3.0.0
  intl: ^0.18.0
  shared_preferences: ^2.2.0
```

---

## 🚀 Installation

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase account
- Git

### Setup Instructions

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/cricrec.git
cd cricrec
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Configuration**

   a. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   
   b. Enable the following services:
      - Authentication (Email/Password)
      - Cloud Firestore
      - Cloud Storage
   
   c. Download configuration files:
      - Android: `google-services.json` → `android/app/`
      - iOS: `GoogleService-Info.plist` → `ios/Runner/`
      - Web: Add Firebase config to `web/index.html`
   
   d. Run FlutterFire CLI:
   ```bash
   flutterfire configure
   ```

4. **Firestore Security Rules**

   Copy and paste these rules in Firebase Console → Firestore Database → Rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth.uid == userId;
       }
       
       match /players/{userId} {
         allow read: if true;
         allow write: if request.auth.uid == userId;
       }
       
       match /matches/{matchId} {
         allow read: if true;
         allow create: if request.auth != null;
         allow update, delete: if request.auth.uid == resource.data.hostId;
         
         match /balls/{ballId} {
           allow read: if true;
           allow write: if request.auth.uid == get(/databases/$(database)/documents/matches/$(matchId)).data.hostId;
         }
       }
     }
   }
   ```

5. **Firestore Indexes**

   Create these composite indexes in Firebase Console:
   - Collection: `matches`
     - Fields: `status` (Ascending), `createdAt` (Descending)
   - Collection: `matches`
     - Fields: `status` (Ascending), `completedAt` (Descending)

6. **Run the app**
```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

---

## 📚 Usage

### For Players

1. **Register & Setup**
   - Create account with email/password
   - Verify email address
   - Complete player profile

2. **Join Matches**
   - Get added to teams by match hosts
   - View your match schedule
   - Track your performance

3. **View Statistics**
   - Check your career stats
   - See your position on leaderboards
   - Review match history

### For Match Hosts

1. **Create Match**
   - Tap "Host Match" button
   - Enter match details
   - Add players to both teams

2. **Conduct Toss**
   - Select toss winner
   - Choose batting/bowling decision

3. **Live Scoring**
   - Record every ball
   - Track runs, wickets, overs
   - Use undo if mistakes occur

4. **Complete Match**
   - Finish both innings
   - View winner declaration
   - Access full scorecard

---

## 📊 Database Schema

### Collections

#### users
```javascript
{
  userId: string (PK),
  email: string,
  emailVerified: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### players
```javascript
{
  userId: string (PK),
  fullName: string,
  email: string,
  jerseyNumber: number,
  playingRole: string,
  battingStyle: string,
  bowlingStyle: string,
  matchesPlayed: number,
  totalRuns: number,
  totalWickets: number,
  highestScore: number,
  centuries: number,
  fiveWicketHauls: number,
  // ... more stats
}
```

#### matches
```javascript
{
  matchId: string (PK),
  matchName: string,
  location: string,
  overs: number,
  ballType: string,
  hostId: string (FK),
  status: string,
  teamA: object,
  teamB: object,
  toss: object,
  innings: object,
  // ... more fields
}
```

#### matches/{matchId}/balls (subcollection)
```javascript
{
  ballId: string (PK),
  inning: number,
  ballNumber: number,
  runs: number,
  isWicket: boolean,
  striker: object,
  bowler: object,
  // ... more fields
}
```

---

## 🏗 Architecture

```
┌─────────────────────────────────────┐
│         PRESENTATION LAYER          │
│  (UI Screens, Widgets, Themes)      │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│       BUSINESS LOGIC LAYER          │
│  (State Management, Validation)     │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│           DATA LAYER                │
│  (Firebase Services, Repositories)  │
└─────────────────────────────────────┘
```

### Key Components

- **Screens**: 15+ screens covering all features
- **Services**: Authentication, Match, Scoring, Statistics
- **Repositories**: User, Player, Match, Ball data access
- **Models**: Data classes for type-safe operations

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

---

## 🤝 Contributing

Contributions are what make the open source community amazing! Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow Flutter/Dart style guide
- Write meaningful commit messages
- Add comments for complex logic
- Update documentation as needed
- Test your changes thoroughly

---

## 🐛 Known Issues & Limitations

1. **Internet Dependency**: Requires active internet for real-time sync
2. **Concurrent Editing**: Only match host can score (no collaborative scoring)
3. **Device Compatibility**: Minimum Android 5.0 / iOS 12.0
4. **Export Options**: Limited data export capabilities (future enhancement)

---

## 🔮 Future Enhancements

- [ ] **Offline Mode**: Complete offline scoring with sync when online
- [ ] **Advanced Analytics**: AI-powered performance insights
- [ ] **Social Features**: Team chat, match invitations, player ratings
- [ ] **Tournament Management**: League creation, knockout brackets, points table
- [ ] **Video Integration**: Ball-by-ball video highlights
- [ ] **Multi-language Support**: Hindi, Gujarati, Tamil, and more
- [ ] **Data Export**: PDF scorecards, CSV export
- [ ] **Live Streaming**: Match commentary and live score broadcasting
- [ ] **Wagon Wheel & Pitch Maps**: Visual ball tracking
- [ ] **Partnership Analysis**: Detailed partnership statistics

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 👥 Authors

**Project Team**
- Student 1 - [GitHub](https://github.com/student1) - student1@example.com
- Student 2 - [GitHub](https://github.com/student2) - student2@example.com
- Student 3 - [GitHub](https://github.com/student3) - student3@example.com

**Project Guide**
- Guide Name - guide@college.edu

---

## 🎓 Academic Information

This project was developed as part of the Bachelor of Computer Application (B.C.A.) program at:

**C.B. Patel Computer College & J.N.M. Patel Science College**  
Bharthana, Vesu, Surat  
Affiliated to Veer Narmad South Gujarat University, Surat  
Academic Year: 2025-2026

---

## 🙏 Acknowledgments

- Flutter and Dart teams for the amazing framework
- Firebase for reliable backend infrastructure
- Material Design for UI/UX guidelines
- Open source community for inspiration
- Our project guide for continuous support
- College faculty for valuable feedback
- Beta testers for helping improve the app

---

## 📞 Contact & Support

- **Project Repository**: [https://github.com/yourusername/cricrec](https://github.com/yourusername/cricrec)
- **Issues**: [Report a Bug](https://github.com/yourusername/cricrec/issues)
- **Email**: cricrec@example.com

---

## ⭐ Show Your Support

Give a ⭐️ if this project helped you or you found it interesting!

---

<div align="center">

**Made with ❤️ and Flutter**

[⬆ Back to Top](#-cricrec---cricket-recording--statistics-management-system)

</div>
