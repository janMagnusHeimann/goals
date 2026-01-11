# Goals - Mac Goal Tracking App

A beautiful native macOS app for tracking your goals with progress visualization, built with SwiftUI and SwiftData.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Goal Types

- **Book Reading**: Track books with cover images (via Google Books), chapter-based notes, reading progress
- **Fitness**: Log training sessions (swim, bike, run, strength, recovery), view activity charts
- **Programming**: Link GitHub repositories, track commits, view contribution stats

### Key Features

- **Visual Progress**: Beautiful progress bars and charts for all goal types
- **CloudKit Sync**: Data syncs across all your devices via iCloud
- **AI-Powered**: Claude AI helps structure your goals after creation
- **GitHub Integration**: OAuth login to track your coding activity
- **System-Adaptive**: Follows macOS light/dark mode

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Apple Developer account (for CloudKit - optional for local-only use)

## Quick Start

### 1. Clone and Open

```bash
git clone https://github.com/yourusername/goals.git
cd goals/Goals
open Goals.xcodeproj
```

### 2. Configure Signing

1. Select the **Goals** project in the navigator
2. Select the **Goals** target
3. Go to **Signing & Capabilities**
4. Select your **Team** (Apple ID)
5. Update **Bundle Identifier** if needed

### 3. Run

Press **⌘R** or click the Play button to build and run.

## Configuration

### CloudKit (Optional)

To enable iCloud sync:

1. In **Signing & Capabilities**, click **+ Capability**
2. Add **iCloud**
3. Check **CloudKit**
4. Create a container (e.g., `iCloud.com.yourname.goals`)

### API Keys

Configure these in the app's Settings (⌘,):

#### Anthropic API Key (for AI features)
1. Get an API key from [Anthropic Console](https://console.anthropic.com/settings/keys)
2. Add it in: Settings → API Keys → Anthropic API Key

#### GitHub OAuth (for programming goals)
1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create a new OAuth App:
   - Application name: `Goals`
   - Homepage URL: `https://github.com/yourusername`
   - Authorization callback URL: `goals://github/callback`
3. Copy Client ID and Client Secret
4. Add them in: Settings → GitHub

## Project Structure

```
Goals/
├── Goals.xcodeproj         # Xcode project
└── Goals/
    ├── GoalsApp.swift      # App entry point
    ├── Models/
    │   ├── Goal.swift      # Base goal model
    │   ├── BookGoal/       # Book, Chapter, ChapterNote
    │   ├── FitnessGoal/    # TrainingSession
    │   └── ProgrammingGoal/# GitHubRepository, CommitActivity
    ├── Views/
    │   ├── Main/           # ContentView, SidebarView
    │   ├── Books/          # Book reading views
    │   ├── Fitness/        # Fitness tracking views
    │   ├── Programming/    # GitHub integration views
    │   ├── Settings/       # Settings view
    │   └── Components/     # Reusable components
    ├── Services/
    │   ├── Books/          # Google Books API
    │   ├── GitHub/         # GitHub OAuth & API
    │   └── AI/             # Claude AI service
    └── Core/
        ├── Extensions/     # Date, Color extensions
        └── Utilities/      # KeychainManager, Constants
```

## Usage

### Creating a Goal

1. Click **+** in the sidebar or press **⌘N**
2. Select goal type (Book Reading, Fitness, or Programming)
3. Enter title and target
4. Click **Create Goal**

### Book Reading

- **Add Books**: Search by title, author, or ISBN
- **Track Progress**: Update current page
- **Add Chapters**: Create chapters to organize notes
- **Take Notes**: Expand chapters to add/edit notes

### Fitness

- **Log Workouts**: Record swim, bike, run, strength, or recovery sessions
- **Track Metrics**: Duration, distance, heart rate, perceived effort
- **View Charts**: Activity over time, workout type breakdown

### Programming

1. Configure GitHub OAuth in Settings
2. Connect your GitHub account
3. Add repositories to track
4. View commit stats and activity

## Technical Notes

### Data Storage

- **Local**: SwiftData with SQLite (works offline)
- **Cloud**: CloudKit sync (optional, requires iCloud)

### API Rate Limits

- **Google Books**: Generally generous limits
- **GitHub**: 5000 requests/hour for authenticated users
- **Anthropic**: Depends on your API plan

### Security

- API keys stored in macOS Keychain
- GitHub tokens stored in Keychain
- Never logged or transmitted insecurely

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with SwiftUI and SwiftData
- Book covers from Google Books API and Open Library
- AI features powered by Claude (Anthropic)
