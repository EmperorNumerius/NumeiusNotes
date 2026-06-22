import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:notes_app/controllers/document_manager.dart';

/// Right-side collapsible panel for live lecture transcription.
/// Uses speech_to_text to transcribe audio in real time.
class TranscriptionPanel extends StatefulWidget {
  const TranscriptionPanel({super.key});

  @override
  State<TranscriptionPanel> createState() => _TranscriptionPanelState();
}

class _TranscriptionPanelState extends State<TranscriptionPanel> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _currentPartial = '';
  final List<_TranscriptEntry> _entries = [];
  final ScrollController _scrollCtrl = ScrollController();
  bool _collapsed = false;
  DateTime? _listenStartTime;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            // Auto-restart for continuous listening
            if (_isListening && mounted) {
              Future.delayed(const Duration(milliseconds: 200), () {
                if (_isListening && mounted) _startListening();
              });
            }
          }
        },
      );
    } catch (e) {
      _isAvailable = false;
    }
    if (mounted) setState(() {});
  }

  void _startListening() {
    if (!_isAvailable) return;
    _listenStartTime ??= DateTime.now();
    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _currentPartial = result.recognizedWords;
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              final elapsed = DateTime.now().difference(_listenStartTime!);
              _entries.add(
                _TranscriptEntry(
                  text: result.recognizedWords,
                  timestamp: elapsed,
                ),
              );
              _currentPartial = '';
              // Save to document
              _saveTranscription();
              // Auto-scroll
              Future.delayed(const Duration(milliseconds: 50), () {
                if (_scrollCtrl.hasClients) {
                  _scrollCtrl.animateTo(
                    _scrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void _saveTranscription() {
    final docMgr = context.read<DocumentManager>();
    final doc = docMgr.activeDocument;
    if (doc != null) {
      doc.transcription = _entries
          .map((e) {
            final mm = e.timestamp.inMinutes
                .remainder(60)
                .toString()
                .padLeft(2, '0');
            final ss = e.timestamp.inSeconds
                .remainder(60)
                .toString()
                .padLeft(2, '0');
            return '[$mm:$ss] ${e.text}';
          })
          .join('\n');
      docMgr.saveActiveDocument();
    }
  }

  void _toggleListening() {
    setState(() {
      if (_isListening) {
        _isListening = false;
        _speech.stop();
      } else {
        _isListening = true;
        _listenStartTime = DateTime.now();
        _startListening();
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_collapsed) {
      return _buildCollapsedBar();
    }
    return _buildExpandedPanel();
  }

  Widget _buildCollapsedBar() {
    return GestureDetector(
      onTap: () => setState(() => _collapsed = false),
      child: Container(
        width: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D20),
          border: Border(left: BorderSide(color: Colors.white.withAlpha(10))),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chevron_left_rounded,
              size: 16,
              color: Colors.white.withAlpha(50),
            ),
            const SizedBox(height: 8),
            RotatedBox(
              quarterTurns: 1,
              child: Text(
                'TRANSCRIPT',
                style: TextStyle(
                  color: Colors.white.withAlpha(40),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (_isListening) ...[
              const SizedBox(height: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D20),
        border: Border(left: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Transcript content
          Expanded(child: _buildTranscriptList()),
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(8))),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mic_rounded,
            size: 14,
            color: _isListening
                ? const Color(0xFFFF6B6B)
                : Colors.white.withAlpha(80),
          ),
          const SizedBox(width: 6),
          Text(
            'Live Transcript',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isListening) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withAlpha(80),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          // Copy all
          if (_entries.isNotEmpty)
            GestureDetector(
              onTap: () {
                // Copy functionality placeholder
              },
              child: Tooltip(
                message: 'Copy transcript',
                child: Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: Colors.white.withAlpha(50),
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Collapse
          GestureDetector(
            onTap: () => setState(() => _collapsed = true),
            child: Tooltip(
              message: 'Collapse transcript',
              child: Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.white.withAlpha(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptList() {
    if (!_isAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic_off_rounded,
                size: 32,
                color: Colors.white.withAlpha(30),
              ),
              const SizedBox(height: 12),
              Text(
                'Speech recognition\nunavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(40),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enable in Windows Settings\n→ Speech',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(25),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty && _currentPartial.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.record_voice_over_rounded,
                size: 28,
                color: Colors.white.withAlpha(20),
              ),
              const SizedBox(height: 12),
              Text(
                'Press Start to begin\nlive transcription',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(30),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: _entries.length + (_currentPartial.isNotEmpty ? 1 : 0),
      itemBuilder: (_, i) {
        if (i < _entries.length) {
          final entry = _entries[i];
          final mm = entry.timestamp.inMinutes
              .remainder(60)
              .toString()
              .padLeft(2, '0');
          final ss = entry.timestamp.inSeconds
              .remainder(60)
              .toString()
              .padLeft(2, '0');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$mm:$ss',
                  style: TextStyle(
                    color: const Color(0xFF00D2FF).withAlpha(120),
                    fontSize: 10,
                    fontFamily: 'Courier New',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.text,
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        // Partial result (live)
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '...',
                style: TextStyle(
                  color: const Color(0xFFFFD43B).withAlpha(120),
                  fontSize: 10,
                  fontFamily: 'Courier New',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentPartial,
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 12,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withAlpha(8))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: _isAvailable ? _toggleListening : null,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: _isListening
                  ? const Color(0xFFFF6B6B).withAlpha(20)
                  : const Color(0xFF00D2FF).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isListening
                    ? const Color(0xFFFF6B6B).withAlpha(60)
                    : const Color(0xFF00D2FF).withAlpha(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 16,
                  color: _isListening
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF00D2FF),
                ),
                const SizedBox(width: 6),
                Text(
                  _isListening ? 'Stop Listening' : 'Start Listening',
                  style: TextStyle(
                    color: _isListening
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF00D2FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TranscriptEntry {
  final String text;
  final Duration timestamp;

  _TranscriptEntry({required this.text, required this.timestamp});
}
