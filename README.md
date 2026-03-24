# 📓 NumeriusNotes

> **The ultimate study and note-taking app for students with ADHD** — built by a uni student, for uni students.

NumeriusNotes is a feature-rich Flutter app designed for iPad, combining everything you'd ever need in a study session into one app. No more switching between a calculator, a PDF viewer, a code editor, and your notes app. It's all here.

---

## ✨ Features

### 📝 Notes & Writing
- Rich text note editor with **Markdown** support
- **LaTeX formula** rendering for math and science notes
- Folder organization and **tabbed navigation** between notes
- Keyboard shortcuts (`Cmd+N`, `Cmd+F`, `Cmd+Shift+N`)

### 📄 PDF Support
- **Import PDFs** from your files
- **Annotate directly** on PDFs
- Full PDF rendering and navigation

### 🎙️ Audio & Transcription
- **Live audio recording** during lectures
- **Live speech-to-text transcription** powered by on-device speech recognition
- Playback of recorded sessions

### 🤖 AI Features
- **AI-generated quizzes** from your notes
- **AI annotations** and document insights

### 🔢 Calculators
- Built-in **standard calculator**
- **Scientific calculator**
- **Graphing calculator**

### 🧪 Reference Tools
- Built-in **Periodic Table of Elements**
- Accessible inline without leaving your notes

### 💻 Code Editor
- Syntax-highlighted **code editor** supporting multiple languages
- Powered by `flutter_highlight`

### 🗂️ Organization
- **Folders** for organizing notes by subject or course
- **Flashcards** for spaced repetition study
- **Tabbed interface** for multitasking between notes

### 🎨 UI/UX
- Responsive layout: **permanent sidebar on wide screens**, drawer on compact
- iPad-first design
- Google Fonts typography

---

## 🛠️ Tech Stack

- **Framework:** Flutter / Dart
- **State Management:** Provider
- **PDF:** `pdfrx`, `syncfusion_flutter_pdf`
- **Audio:** `record`, `audioplayers`
- **Speech:** `speech_to_text`
- **Math:** `flutter_math_fork`
- **Code Highlighting:** `flutter_highlight`
- **File Handling:** `file_picker`, `path_provider`
- **Storage:** `shared_preferences`, `flutter_secure_storage`

---

## 🚧 Status

This project is actively in development and has known bugs. The current build targets **iPad and Windows**. A full iOS/iPadOS-optimized rewrite is planned pending access to a macOS development environment (required for Xcode and `flutter build ios`).

**Completed (~120 commits):**
- Core note editor
- PDF import and annotation
- Audio recording and transcription
- LaTeX, Markdown, code editor
- Calculator suite
- Folder/tab organization
- AI quiz generation

**Planned / In Progress:**
- iPad layout polish and optimization
- Performance improvements (current build size is too large)
- Bug fixes across all features
- App Store submission

---

## 🏗️ Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- For iOS/iPad builds: **macOS with Xcode** (required)
- For Windows builds: Visual Studio with C++ workload

### Run locally
```bash
flutter pub get
flutter run
```

### Build for iOS/iPad
```bash
# Requires macOS + Xcode
flutter build ios
# Then open ios/Runner.xcworkspace in Xcode to configure signing
```

### Permissions (iOS Info.plist)
The app requires the following permissions configured in `ios/Runner/Info.plist`:
- Microphone — for audio recording
- Speech Recognition — for live transcription
- Photo Library — for importing images
- Camera — for taking photos
- File Sharing — for document management

---

## 📁 Project Structure

```
lib/
├── controllers/   # State management (Providers)
├── models/        # Data models (Document, Folder, etc.)
├── widgets/       # UI components and pages
└── services/      # External services (PDF, Audio, Image)
```

---

## 🤝 Contributing

This is a solo project but PRs and issues are welcome. If you're a student with ADHD and have feature ideas, open an issue!

---

## 👤 Author

Built by [@EmperorNumerius](https://github.com/EmperorNumerius) — a uni student who couldn't find a notes app that worked for their brain, so they built one.
