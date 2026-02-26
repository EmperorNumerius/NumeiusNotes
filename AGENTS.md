# Developer Notes for Notes App

## Overview
This is a Flutter-based notes application with support for audio recording, PDF annotation, and AI features.

## iPad Deployment and iOS Support
To deploy to an iPad or iOS device:
1. Ensure you have a Mac with Xcode installed.
2. Run `flutter build ios` to build the app.
3. Open `ios/Runner.xcworkspace` in Xcode to configure signing and capabilities.

### Info.plist Configuration
The `ios/Runner/Info.plist` file has been configured with the following keys to support app features:
- `NSMicrophoneUsageDescription`: For audio recording.
- `NSSpeechRecognitionUsageDescription`: For speech-to-text.
- `NSPhotoLibraryUsageDescription`: For importing images.
- `NSCameraUsageDescription`: For taking photos.
- `UIFileSharingEnabled` & `LSSupportsOpeningDocumentsInPlace`: For file management.

If you add new features requiring permissions, ensure to update `Info.plist`.

## Responsive Design
The `HomePage` (`lib/widgets/home_page.dart`) uses a `LayoutBuilder` to adapt to different screen sizes:
- **Wide Screens (>= 700px)**: Displays a permanent sidebar on the left.
- **Compact Screens (< 700px)**: Hides the sidebar and provides a hamburger menu to open it as a Drawer.

## Keyboard Shortcuts
The app supports keyboard shortcuts on the Home Page:
- `Ctrl/Cmd + N`: Create a new note.
- `Ctrl/Cmd + Shift + N`: Create a new folder.
- `Ctrl/Cmd + F`: Focus the search bar.

## Project Structure
- `lib/controllers/`: State management (Providers).
- `lib/models/`: Data models (Document, Folder, etc.).
- `lib/widgets/`: UI components and pages.
- `lib/services/`: External services (PDF, Audio, Image).

## Testing
Run `flutter test` to execute the test suite.
