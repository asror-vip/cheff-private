import 'package:chefcontrol/core/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/entities/ai_agent_action_entity.dart';
import '../../../../core/theme/app_colors.dart';
import 'agent_action_card.dart';

class AiChatBubble extends StatelessWidget {
  final AiMessageEntity message;

  const AiChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);
    final hasAction = message.actionData != null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF246BFD)
              : const Color(0xFF1E2633),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(3) : const Radius.circular(16),
            bottomLeft: !isUser ? const Radius.circular(3) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
          border: Border.all(
            color: isUser
                ? Colors.blueAccent.withValues(alpha: 0.3)
                : Colors.white12,
            width: 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: message.text));
              HapticFeedback.lightImpact();
              ToastUtils.showSuccess(context, 'Nusxa olindi');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ChefControl AI',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  if (hasAction) ...[
                    AgentActionCard(
                      action: AgentActionEntity.fromMap(message.actionData!),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isUser ? Colors.white70 : Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
