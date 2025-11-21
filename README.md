# Streamflix

A Netflix-like streaming frontend for TV built with Flutter, designed to work with Jellyfin and Jellyseerr backends.

## Features

- **Netflix-style UI** - Beautiful dark theme with horizontal carousels
- **TV Remote Navigation** - Full D-pad support with focus management
- **Jellyfin Integration** - Browse, search, and play media from your Jellyfin server
- **Jellyseerr Integration** - Request new movies and TV shows
- **Cross-platform** - Works on Android TV, Fire TV, and mobile devices

## Screens

- **Splash Screen** - Loading animation with logo
- **Login Screen** - Jellyfin server connection and authentication
- **Home Screen** - Hero banner, Continue Watching, Latest Movies/TV Shows
- **Details Screen** - Movie/show details with seasons and episodes
- **Player Screen** - Video playback with controls
- **Search Screen** - Search your media library
- **Settings Screen** - Server configuration and sign out

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App widget with routing
├── core/
│   ├── config/               # App configuration
│   ├── navigation/           # TV focus management & routing
│   ├── theme/                # Netflix-style dark theme
│   └── utils/                # Utility functions
├── data/
│   ├── jellyfin/             # Jellyfin API client
│   └── jellyseerr/           # Jellyseerr API client
├── domain/
│   └── models/               # Data models
└── presentation/
    ├── screens/              # App screens
    ├── widgets/              # Reusable widgets
    └── providers/            # Riverpod providers
```

## Getting Started

### Prerequisites

- Flutter SDK (3.2.0 or higher)
- Jellyfin server
- (Optional) Jellyseerr for media requests

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Android TV

```bash
flutter build apk --release
```

The APK includes the necessary manifest configurations for Android TV / Fire TV launcher integration.

## Configuration

### Jellyfin Setup

1. Launch the app
2. Enter your Jellyfin server URL (e.g., `http://192.168.1.100:8096`)
3. Enter your username and password
4. Start browsing!

### Jellyseerr Setup (Optional)

1. Go to Settings
2. Click "Configure Jellyseerr"
3. Enter your Jellyseerr URL and API key
4. You can now request new media from the search screen

## TV Remote Controls

| Button | Action |
|--------|--------|
| D-pad | Navigate between items |
| Select/Enter | Activate focused item |
| Back | Go back / Exit |
| Left/Right (in player) | Seek -/+ 10 seconds |
| Play/Pause | Toggle playback |

## Dependencies

- `flutter_riverpod` - State management
- `dio` - HTTP client
- `go_router` - Navigation
- `media_kit` - Video playback
- `cached_network_image` - Image caching
- `hive` - Local storage

## Video Playback

The app uses `media_kit` for video playback, which provides:
- Direct stream from Jellyfin
- Playback position tracking
- Resume functionality

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use this project for your own streaming setup.

## Acknowledgments

- [Jellyfin](https://jellyfin.org/) - The free software media system
- [Jellyseerr](https://github.com/Fallenbagel/jellyseerr) - Media request manager
- [Jellyflix](https://github.com/jellyflix-app/jellyflix) - Flutter Jellyfin client inspiration
