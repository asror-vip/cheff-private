import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class TelegramVoiceRecordBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isListening;
  final bool isLoading;
  final double soundLevel;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final ValueChanged<String> onSendText;
  final VoidCallback onOpenQuickPresets;

  const TelegramVoiceRecordBar({
    super.key,
    required this.controller,
    required this.isListening,
    required this.isLoading,
    this.soundLevel = 0.0,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.onSendText,
    required this.onOpenQuickPresets,
  });

  @override
  State<TelegramVoiceRecordBar> createState() => _TelegramVoiceRecordBarState();
}

class _TelegramVoiceRecordBarState extends State<TelegramVoiceRecordBar>
    with SingleTickerProviderStateMixin {
  bool _hasText = false;
  double _dragOffset = 0.0;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() {
        _hasText = has;
      });
    }
  }

  @override
  void didUpdateWidget(covariant TelegramVoiceRecordBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _recordSeconds = 0;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordSeconds++;
          });
        }
      });
    } else if (!widget.isListening && oldWidget.isListening) {
      _recordTimer?.cancel();
      _recordTimer = null;
      _dragOffset = 0.0;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _recordTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      widget.controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF17212B),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: widget.isListening
            ? _buildRecordingBar()
            : _buildInputBar(),
      ),
    );
  }

  Widget _buildRecordingBar() {
    final minutes = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordSeconds % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(
                  alpha: 0.5 + (_pulseController.value * 0.5),
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          '$minutes:$seconds',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            children: [
              const Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
                size: 18,
              ),
              Expanded(
                child: Text(
                  'ai_assistant.slide_to_cancel'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.redAccent),
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.onCancelRecording();
          },
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onStopRecording();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF246BFD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.bolt, color: Colors.amber, size: 24),
          tooltip: 'ai_assistant.quick_commands'.tr(),
          onPressed: widget.onOpenQuickPresets,
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF242F3D),
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: widget.controller,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'ai_assistant.input_hint'.tr(),
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _hasText
            ? GestureDetector(
                onTap: widget.isLoading ? null : _handleSend,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF246BFD),
                    shape: BoxShape.circle,
                  ),
                  child: widget.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              )
            : GestureDetector(
                onLongPressStart: (_) {
                  HapticFeedback.heavyImpact();
                  widget.onStartRecording();
                },
                onLongPressMoveUpdate: (details) {
                  _dragOffset += details.offsetFromOrigin.dx;
                  if (_dragOffset < -70) {
                    HapticFeedback.mediumImpact();
                    widget.onCancelRecording();
                  }
                },
                onLongPressEnd: (_) {
                  if (_dragOffset >= -70) {
                    HapticFeedback.lightImpact();
                    widget.onStopRecording();
                  }
                },
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onStartRecording();
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF246BFD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
      ],
    );
  }
}
