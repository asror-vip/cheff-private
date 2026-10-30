import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AiVoiceBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final int durationSeconds;
  final DateTime timestamp;

  const AiVoiceBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.durationSeconds,
    required this.timestamp,
  });

  @override
  State<AiVoiceBubble> createState() => _AiVoiceBubbleState();
}

class _AiVoiceBubbleState extends State<AiVoiceBubble> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${widget.timestamp.hour.toString().padLeft(2, '0')}:${widget.timestamp.minute.toString().padLeft(2, '0')}';
    final durationStr =
        '0:${widget.durationSeconds.toString().padLeft(2, '0')}';

    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: widget.isUser
              ? Colors.blueAccent.withValues(alpha: 0.85)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: widget.isUser ? const Radius.circular(2) : const Radius.circular(16),
            bottomLeft: !widget.isUser ? const Radius.circular(2) : const Radius.circular(16),
          ),
          border: Border.all(
            color: widget.isUser
                ? Colors.blueAccent.withValues(alpha: 0.3)
                : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.isUser
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.blueAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isUser ? Colors.white : Colors.blueAccent,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ai styled sound waveform
                      Row(
                        children: List.generate(18, (index) {
                          final heights = [
                            8.0, 14.0, 22.0, 12.0, 18.0, 26.0, 16.0, 10.0,
                            20.0, 14.0, 28.0, 12.0, 18.0, 24.0, 14.0, 10.0,
                            16.0, 8.0
                          ];
                          final height = heights[index % heights.length];
                          final isPassed = _isPlaying && index < 9;

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              height: height,
                              decoration: BoxDecoration(
                                color: isPassed
                                    ? Colors.cyanAccent
                                    : (widget.isUser
                                        ? Colors.white70
                                        : Colors.white38),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            durationStr,
                            style: TextStyle(
                              color: widget.isUser ? Colors.white70 : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: widget.isUser ? Colors.white60 : Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.isUser ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
