import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/smart_gpt_cubit.dart';
import '../cubit/smart_gpt_state.dart';
import '../models/smart_gpt_conversation.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/new_chat_button.dart';
import '../widgets/smart_gpt_fab.dart';
import '../widgets/typing_indicator.dart';

/// Subtle blue -> purple page background used across the SmartGPT screen.
const _kBgTop = Color(0xFFEEF1FB);
const _kBgBottom = Color(0xFFF6F0FC);

class SmartGPTScreen extends StatefulWidget {
  const SmartGPTScreen({super.key});

  @override
  State<SmartGPTScreen> createState() => _SmartGPTScreenState();
}

class _SmartGPTScreenState extends State<SmartGPTScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  // Bumped every time the drawer opens so its history list reloads fresh.
  int _drawerTick = 0;

  // ChatGPT-style auto-follow: keep pinned to the latest text while streaming,
  // but pause the moment the user scrolls up, and resume when they come back
  // near the bottom.
  bool _autoFollow = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final distance =
        _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    // Returned near the bottom -> resume following.
    if (distance < 60) _autoFollow = true;
    // Moved meaningfully upward -> stop following.
    if (distance > 120) _autoFollow = false;
  }

  void _scrollToBottom({bool animated = true, bool force = false}) {
    if (!force && !_autoFollow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _send([String? text]) {
    final value = text ?? _inputController.text;
    if (value.trim().isEmpty) return;
    // Sending a new message should always snap to the bottom.
    _autoFollow = true;
    context.read<SmartGptCubit>().sendMessage(value);
    _inputController.clear();
    _inputFocus.unfocus();
  }

  void _newChat() {
    context.read<SmartGptCubit>().startNewChat();
    _inputController.clear();
    _inputFocus.unfocus();
  }

  void _openDrawer() {
    _inputFocus.unfocus();
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onSelectConversation(SmartGptConversation conversation) {
    _autoFollow = true;
    context.read<SmartGptCubit>().loadConversation(conversation);
    _scrollToBottom(animated: false, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBgTop,
      appBar: _buildAppBar(context),
      drawerEnableOpenDragGesture: false,
      onDrawerChanged: (isOpen) {
        if (isOpen) setState(() => _drawerTick++);
      },
      drawer: _HistoryDrawer(
        key: ValueKey(_drawerTick),
        onSelect: _onSelectConversation,
        onNewChat: _newChat,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kBgTop, _kBgBottom],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                // The instant the user puts a finger down to scroll, stop
                // auto-following so streaming text doesn't yank them back.
                onPanDown: (_) => _autoFollow = false,
                child: BlocConsumer<SmartGptCubit, SmartGptState>(
                  listener: (context, state) => _scrollToBottom(),
                  builder: (context, state) {
                    if (!state.hasMessages) {
                      return _WelcomeView(onSuggestionTap: _send);
                    }
                    return _buildChatList(state);
                  },
                ),
              ),
            ),
            _InputBar(
              controller: _inputController,
              focusNode: _inputFocus,
              onSend: () => _send(),
              onAdd: _newChat,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: IconButton(
        tooltip: 'Chat history',
        icon: const Icon(Icons.menu_rounded),
        color: AppColors.textPrimary,
        onPressed: _openDrawer,
      ),
      title: Row(
        children: [
          Hero(
            tag: kSmartGptHeroTag,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: AppColors.smartGptGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              'SmartGPT',
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Only relevant once a chat has started.
        BlocBuilder<SmartGptCubit, SmartGptState>(
          buildWhen: (a, b) => a.hasMessages != b.hasMessages,
          builder: (context, state) {
            if (!state.hasMessages) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: NewChatButton(onPressed: _newChat),
            );
          },
        ),
        _CloseButton(onPressed: () => context.pop()),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildChatList(SmartGptState state) {
    final lastIndex = state.messages.length - 1;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: state.messages.length + (state.isAwaitingResponse ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: _AwaitingBubble(),
          );
        }
        final message = state.messages[index];
        final animate = index == lastIndex && message.isAi && !message.isError;
        return ChatBubble(
          key: ValueKey(message.id),
          message: message,
          animate: animate,
          onProgress: () => _scrollToBottom(animated: false),
        );
      },
    );
  }
}

class _HistoryDrawer extends StatefulWidget {
  final void Function(SmartGptConversation conversation) onSelect;
  final VoidCallback onNewChat;

  const _HistoryDrawer({
    super.key,
    required this.onSelect,
    required this.onNewChat,
  });

  @override
  State<_HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<_HistoryDrawer> {
  late Future<List<SmartGptConversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SmartGptCubit>().loadHistory();
  }

  void _reload() {
    setState(() {
      _future = context.read<SmartGptCubit>().loadHistory();
    });
  }

  Future<void> _delete(SmartGptConversation conversation) async {
    await context.read<SmartGptCubit>().deleteConversation(conversation.id);
    if (mounted) _reload();
  }

  void _close() => Scaffold.of(context).closeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _kBgTop,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      gradient: AppColors.smartGptGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SmartGPT',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: NewChatButton(
                  onPressed: () {
                    _close();
                    widget.onNewChat();
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Text(
                'RECENT CHATS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textHint,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SmartGptConversation>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const _DrawerEmpty();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final conversation = items[index];
                      return _DrawerHistoryTile(
                        conversation: conversation,
                        onTap: () {
                          _close();
                          widget.onSelect(conversation);
                        },
                        onDelete: () => _delete(conversation),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHistoryTile extends StatelessWidget {
  final SmartGptConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DrawerHistoryTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: AppColors.accentPurple,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(conversation.updatedAt),
                      style: AppTextStyles.labelMedium,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Options',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textHint,
                ),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.accentRed,
                        ),
                        SizedBox(width: 10),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _DrawerEmpty extends StatelessWidget {
  const _DrawerEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 40,
              color: AppColors.textHint.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text('No chats yet', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Your conversations will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AwaitingBubble extends StatelessWidget {
  const _AwaitingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            gradient: AppColors.smartGptGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const TypingIndicator(),
        ),
      ],
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final void Function(String prompt) onSuggestionTap;

  const _WelcomeView({required this.onSuggestionTap});

  static const _suggestions = <_Suggestion>[
    _Suggestion(
      label: 'Explain Pythagoras Theorem',
      icon: Icons.calculate_rounded,
      prompt: 'Explain the Pythagoras Theorem with a simple example',
    ),
    _Suggestion(
      label: 'Photosynthesis',
      icon: Icons.eco_rounded,
      prompt: 'Explain Photosynthesis in simple terms with an example',
    ),
    _Suggestion(
      label: "Newton's Second Law",
      icon: Icons.science_rounded,
      prompt: "Explain Newton's Second Law of Motion with an example",
    ),
    _Suggestion(
      label: 'Telugu Explanation',
      icon: Icons.translate_rounded,
      prompt:
          'కిరణజన్య సంయోగక్రియ (Photosynthesis) గురించి తెలుగులో '
          'సులభంగా వివరించండి',
    ),
    _Suggestion(
      label: 'Generate Quiz',
      icon: Icons.quiz_rounded,
      prompt:
          'Generate a 5-question multiple choice quiz on Science for '
          'Class 10 with answers',
    ),
    _Suggestion(
      label: 'Exam Preparation Tips',
      icon: Icons.tips_and_updates_rounded,
      prompt: 'Give me effective exam preparation tips for board exams',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: AppColors.smartGptGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'How can I help you today?',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ask anything from Class 8 to Inter 2nd Year — in English or Telugu.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _suggestions
              .map(
                (s) => _SuggestionChip(
                  suggestion: s,
                  onTap: () => onSuggestionTap(s.prompt),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Suggestion {
  final String label;
  final IconData icon;
  final String prompt;

  const _Suggestion({
    required this.label,
    required this.icon,
    required this.prompt,
  });
}

class _SuggestionChip extends StatelessWidget {
  final _Suggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionChip({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(suggestion.icon, size: 18, color: AppColors.accentPurple),
              const SizedBox(width: 8),
              Text(
                suggestion.label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAdd;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'New chat',
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              color: AppColors.textSecondary,
              iconSize: 26,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Ask anything about your studies...',
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textHint,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _SendButton(controller: controller, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _SendButton({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final enabled = value.text.trim().isNotEmpty;
        return Padding(
          padding: const EdgeInsets.only(bottom: 2, right: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onSend : null,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: enabled ? AppColors.smartGptGradient : null,
                  color: enabled ? null : const Color(0xFFE9E9F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: enabled ? Colors.white : AppColors.textHint,
                  size: 22,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
