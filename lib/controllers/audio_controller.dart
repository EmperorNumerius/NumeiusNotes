import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Controls audio recording and playback, exposing a stream of current position.
class AudioController extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _recordingTimer;
  final Stopwatch _stopwatch = Stopwatch();

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  /// Milliseconds elapsed since recording started (for timestamping strokes).
  int get elapsedRecordingMs => _stopwatch.elapsedMilliseconds;

  AudioController() {
    _player.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });
    _player.onDurationChanged.listen((dur) {
      _totalDuration = dur;
      notifyListeners();
    });
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      notifyListeners();
    });
  }

  Future<void> startRecording(String documentId) async {
    if (_isRecording) return;
    if (!await _recorder.hasPermission()) return;

    final appDir = await getApplicationDocumentsDirectory();
    _currentRecordingPath =
        '${appDir.path}/NotesApp/${documentId}_audio.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: _currentRecordingPath!,
    );

    _isRecording = true;
    _stopwatch.reset();
    _stopwatch.start();

    // Update UI periodically during recording
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _currentPosition = Duration(milliseconds: _stopwatch.elapsedMilliseconds);
      notifyListeners();
    });

    notifyListeners();
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    _stopwatch.stop();
    _recordingTimer?.cancel();
    _recordingTimer = null;
    notifyListeners();
    return path;
  }

  Future<void> play(String path) async {
    await _player.play(DeviceFileSource(path));
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _currentPosition = position;
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }
}
