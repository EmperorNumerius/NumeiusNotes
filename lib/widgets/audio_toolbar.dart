import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/controllers/audio_controller.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/controllers/canvas_controller.dart';

/// Notability-style audio toolbar — record, play, seek, with sync controls.
class AudioToolbar extends StatelessWidget {
  const AudioToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final audioCtrl = context.watch<AudioController>();
    final docMgr = context.watch<DocumentManager>();
    final canvasCtrl = context.read<CanvasController>();
    final doc = docMgr.activeDocument;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F23),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(20)),
        ),
      ),
      child: Row(
        children: [
          // Record button
          _CircleButton(
            icon: audioCtrl.isRecording ? Icons.stop : Icons.fiber_manual_record,
            color: audioCtrl.isRecording
                ? const Color(0xFFFF6B6B)
                : const Color(0xFFFF6B6B).withAlpha(180),
            size: 32,
            pulse: audioCtrl.isRecording,
            onTap: () async {
              if (audioCtrl.isRecording) {
                final path = await audioCtrl.stopRecording();
                if (path != null && doc != null) {
                  doc.audioPath = path;
                  docMgr.saveActiveDocument();
                }
              } else if (doc != null) {
                await audioCtrl.startRecording(doc.id);
              }
            },
          ),
          const SizedBox(width: 12),
          // Play / Pause button
          _CircleButton(
            icon: audioCtrl.isPlaying ? Icons.pause : Icons.play_arrow,
            color: const Color(0xFF00D2FF),
            size: 32,
            onTap: () async {
              if (audioCtrl.isPlaying) {
                await audioCtrl.pause();
                canvasCtrl.setPlaybackMode(false);
              } else if (doc?.audioPath != null) {
                canvasCtrl.setPlaybackMode(true);
                await audioCtrl.play(doc!.audioPath!);
                // Update playback position continuously
                audioCtrl.addListener(() {
                  if (audioCtrl.isPlaying) {
                    canvasCtrl.setPlaybackTime(
                        audioCtrl.currentPosition.inMilliseconds);
                  }
                });
              }
            },
          ),
          const SizedBox(width: 16),
          // Seek bar
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor: const Color(0xFF00D2FF),
                    thumbColor: const Color(0xFF00D2FF),
                    inactiveTrackColor: Colors.white12,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: audioCtrl.totalDuration.inMilliseconds > 0
                        ? audioCtrl.currentPosition.inMilliseconds
                            .toDouble()
                            .clamp(
                                0,
                                audioCtrl.totalDuration.inMilliseconds
                                    .toDouble())
                        : 0,
                    min: 0,
                    max: audioCtrl.totalDuration.inMilliseconds > 0
                        ? audioCtrl.totalDuration.inMilliseconds.toDouble()
                        : 1,
                    onChanged: (v) {
                      audioCtrl.seek(Duration(milliseconds: v.toInt()));
                      canvasCtrl.setPlaybackTime(v.toInt());
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(audioCtrl.currentPosition),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                      if (audioCtrl.isRecording)
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B6B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('REC',
                                style: TextStyle(
                                    color: Color(0xFFFF6B6B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      Text(
                        _formatDuration(audioCtrl.totalDuration),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sync mode indicator
          if (doc?.audioPath != null)
            _CircleButton(
              icon: Icons.sync,
              color: canvasCtrl.playbackMode
                  ? const Color(0xFF51CF66)
                  : Colors.white24,
              size: 28,
              onTap: () {
                canvasCtrl.setPlaybackMode(!canvasCtrl.playbackMode);
              },
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _CircleButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final bool pulse;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.pulse = false,
  });

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.pulse) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _CircleButton old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.pulse && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        final scale = widget.pulse ? 1.0 + _pulseCtrl.value * 0.15 : 1.0;
        return GestureDetector(
          onTap: widget.onTap,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withAlpha(30),
                border: Border.all(color: widget.color.withAlpha(120)),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withAlpha(40),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Icon(widget.icon,
                  color: widget.color,
                  size: widget.size * 0.5),
            ),
          ),
        );
      },
    );
  }
}
