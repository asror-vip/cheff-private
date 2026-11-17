import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../providers/ai_assistant_provider.dart';
import '../widgets/ai_chat_bubble.dart';
import '../widgets/ai_voice_bubble.dart';
import '../widgets/ai_voice_record_bar.dart';
import '../widgets/quick_voice_sheet.dart';

class AiAssistantPage extends StatelessWidget {
  final VoidCallback? onBack;

  const AiAssistantPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AiAssistantProvider(),
      child: AiAssistantView(onBack: onBack),
    );
  }
}

class AiAssistantView extends StatefulWidget {
  final VoidCallback? onBack;

  const AiAssistantView({super.key, this.onBack});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showQuickPresets(BuildContext context, AiAssistantProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickVoiceSheet(
        onSelectCommand: (cmd) {
          provider.sendTextMessage(cmd);
        },
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, AiAssistantProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'ai_assistant.clear_chat'.tr(),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          'ai_assistant.clear_chat_confirm'.tr(),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              provider.clearChat();
            },
            child: Text('common.clear'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiAssistantProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
        ),
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (widget.onBack != null) {
              widget.onBack!();
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF246BFD), Color(0xFF00C6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ChefControl AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ai_assistant.bot_status'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.amber),
            tooltip: 'ai_assistant.quick_commands'.tr(),
            onPressed: () => _showQuickPresets(context, provider),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConfirmDialog(context, provider);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'ai_assistant.clear_chat'.tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.messages.isEmpty && !provider.isLoading
                ? _buildEmptyGreeting(context, provider)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            _buildDateBadge(context),
                            const SizedBox(height: 8),
                            _buildMessageItem(provider.messages[index]),
                          ],
                        );
                      }

                      if (index < provider.messages.length) {
                        return _buildMessageItem(provider.messages[index]);
                      }

                      return _buildTypingIndicator();
                    },
                  ),
          ),
          AiVoiceRecordBar(
            controller: _textController,
            isListening: provider.isListening,
            isLoading: provider.isLoading,
            soundLevel: provider.soundLevel,
            onStartRecording: () {
              provider.startListening(localeId: context.locale.toString());
            },
            onStopRecording: () {
              provider.stopListeningAndSend();
            },
            onCancelRecording: () {
              provider.cancelListening();
            },
            onSendText: (text) {
              provider.sendTextMessage(text);
            },
            onOpenQuickPresets: () => _showQuickPresets(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        child: Text(
          DateFormat('d MMMM, yyyy', context.locale.toString()).format(DateTime.now()),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(AiMessageEntity msg) {
    if (msg.type == AiMessageType.voice) {
      return AiVoiceBubble(
        text: msg.text,
        isUser: msg.isUser,
        durationSeconds: msg.voiceDurationSeconds ?? 2,
        timestamp: msg.timestamp,
      );
    }

    return AiChatBubble(message: msg);
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(3),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF246BFD),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ai_assistant.listening'.tr(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGreeting(BuildContext context, AiAssistantProvider provider) {
    final actions = [
      (Icons.add_circle_outline_rounded, const Color(0xFF246BFD), 'ai_assistant.action_create_ttk'),
      (Icons.calculate_outlined, const Color(0xFFFF7A00), 'ai_assistant.action_calc_foodcost'),
      (Icons.menu_book_rounded, const Color(0xFFE67E22), 'ai_assistant.action_create_menu'),
      (Icons.shopping_cart_outlined, const Color(0xFF10B981), 'ai_assistant.action_purchase_req'),
      (Icons.bar_chart_rounded, const Color(0xFF6366F1), 'ai_assistant.action_sales_analysis'),
      (Icons.people_outline_rounded, const Color(0xFF06B6D4), 'ai_assistant.action_staff_schedule'),
      (Icons.description_outlined, const Color(0xFFF59E0B), 'ai_assistant.action_finance_report'),
      (Icons.chat_bubble_outline_rounded, const Color(0xFF94A3B8), 'ai_assistant.action_any_question'),
    ];

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF246BFD), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF246BFD).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 46,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ai_assistant.greeting'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          ...actions.map((act) {
            final icon = act.$1;
            final color = act.$2;
            final labelKey = act.$3;
            final label = labelKey.tr();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    provider.sendTextMessage(label);
                  },
                  splashColor: color.withValues(alpha: 0.14),
                  highlightColor: color.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.32),
                              width: 1,
                            ),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
