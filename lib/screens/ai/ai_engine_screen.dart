import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/providers/members_provider.dart';
import 'package:gymsaas/providers/chat_provider.dart';
import 'package:gymsaas/services/ai_service.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/apex_card.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/apex_progress_bar.dart';
import 'package:gymsaas/widgets/sparkline_widget.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class AiEngineScreen extends ConsumerStatefulWidget {
  const AiEngineScreen({super.key});

  @override
  ConsumerState<AiEngineScreen> createState() => _AiEngineScreenState();
}

class _AiEngineScreenState extends ConsumerState<AiEngineScreen> {
  Member? _selected;
  int _modeIdx = 0;
  bool _loading = false;
  String _output = '';
  String? _responseMessage;
  AiResponseKind? _responseKind;
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _ai = AiService();

  static const _modes = [
    {'label': 'Coach', 'icon': Icons.fitness_center_rounded, 'color': 0xFFC9A84C},
    {'label': 'Churn', 'icon': Icons.warning_amber_rounded, 'color': 0xFFE05252},
    {'label': 'Nutrition', 'icon': Icons.restaurant_rounded, 'color': 0xFF3DBA7E},
    {'label': 'Chat', 'icon': Icons.chat_bubble_rounded, 'color': 0xFF4C7CE0},
  ];

  Future<void> _runAi() async {
    if (_selected == null || _loading) return;
    setState(() {
      _loading = true;
      _output = '';
      _responseMessage = null;
      _responseKind = null;
    });

    final mode = ['coach', 'churn', 'nutrition', 'chat'][_modeIdx];
    await for (final event in _ai.analyze(
      member: _selected!,
      mode: mode,
      allowDemoFallback: kDebugMode,
    )) {
      if (!mounted) return;
      setState(() {
        _responseKind = event.kind;
        if (event.message != null) {
          _responseMessage = event.message;
        }
        if (event.textChunk != null) {
          _output += event.textChunk!;
        }
      });
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendChat(String msg) async {
    if (_selected == null || msg.trim().isEmpty) return;
    final memberId = _selected!.id;
    ref.read(chatProvider(memberId).notifier).addMessage(
      ChatMessage(text: msg, isUser: true, time: DateTime.now()),
    );
    _chatCtrl.clear();
    ref.read(chatProvider(memberId).notifier).addMessage(
      ChatMessage(text: '', isUser: false, time: DateTime.now()),
    );

    var addedDemoLabel = false;
    await for (final event in _ai.analyze(
      member: _selected!,
      mode: 'chat',
      userMessage: msg,
      allowDemoFallback: kDebugMode,
    )) {
      if (!mounted) return;
      if (event.kind == AiResponseKind.demo && !addedDemoLabel) {
        ref.read(chatProvider(memberId).notifier).appendToLast(
          '[DEMO ONLY]\n${event.message ?? ''}\n\n',
        );
        addedDemoLabel = true;
      }
      if (event.kind == AiResponseKind.unavailable) {
        ref.read(chatProvider(memberId).notifier).appendToLast(
          event.message ?? 'AI backend unavailable.',
        );
      }
      if (event.textChunk != null) {
        ref.read(chatProvider(memberId).notifier).appendToLast(event.textChunk!);
      }
    }
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Widget _buildMemberList(List<Member> members, bool isMobile) {
    if (isMobile) {
      return SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: members.length,
          itemBuilder: (_, i) {
            final m = members[i];
            final sel = _selected?.id == m.id;
            final risk = churnRisk(m);
            return GestureDetector(
              onTap: () => setState(() {
                _selected = m;
                _output = '';
                _responseMessage = null;
                _responseKind = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                width: 80,
                decoration: BoxDecoration(
                  color: sel ? gold.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? gold.withOpacity(0.3) : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: churnColor(risk),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ApexText(
                      m.name.split(' ').first,
                      fontSize: 10,
                      color: sel ? const Color(0xFFE8E8E8) : const Color(0xFF888888),
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                    const SizedBox(height: 2),
                    ApexBadge(
                      text: m.plan,
                      color: m.plan == 'Elite'
                          ? gold
                          : m.plan == 'Premium'
                              ? blueInfo
                              : const Color(0xFF555555),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      width: 220,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: borderDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: GoldHeading('AI Engine', fontSize: 14),
            ),
            const Divider(color: borderDark, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final m = members[i];
                  final sel = _selected?.id == m.id;
                  final risk = churnRisk(m);
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selected = m;
                      _output = '';
                      _responseMessage = null;
                      _responseKind = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? gold.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? gold.withOpacity(0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: churnColor(risk),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ApexText(
                                  m.name,
                                  fontSize: 12,
                                  color: sel ? const Color(0xFFE8E8E8) : const Color(0xFF888888),
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                ),
                                const SizedBox(height: 2),
                                ApexBadge(
                                  text: m.plan,
                                  color: m.plan == 'Elite'
                                      ? gold
                                      : m.plan == 'Premium'
                                          ? blueInfo
                                          : const Color(0xFF555555),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPanel() {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderDark)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_modes.length, (i) {
                  final mode = _modes[i];
                  final active = _modeIdx == i;
                  final c = Color(mode['color'] as int);
                  return GestureDetector(
                    onTap: () => setState(() {
                      _modeIdx = i;
                      _output = '';
                      _responseMessage = null;
                      _responseKind = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? c.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? c.withOpacity(0.3) : borderDark,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mode['icon'] as IconData,
                            color: active ? c : const Color(0xFF444444),
                            size: 14,
                          ),
                          if (!isMobile()) const SizedBox(width: 6),
                          if (!isMobile())
                            ApexText(
                              mode['label'] as String,
                              fontSize: 12,
                              color: active ? c : const Color(0xFF555555),
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: _selected == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_rounded, color: Color(0xFF2A2A2A), size: 48),
                        SizedBox(height: 12),
                        ApexText('Select a member to begin', color: Color(0xFF444444)),
                      ],
                    ),
                  )
                : _modeIdx == 3
                    ? _ChatPanel(
                        member: _selected!,
                        chatCtrl: _chatCtrl,
                        onSend: _sendChat,
                      )
                    : _AnalysisPanel(
                        member: _selected!,
                        modeIdx: _modeIdx,
                        loading: _loading,
                        output: _output,
                        scrollCtrl: _scrollCtrl,
                        onRun: _runAi,
                        responseKind: _responseKind,
                        responseMessage: _responseMessage,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    if (_selected == null) return const SizedBox.shrink();
    return SizedBox(
      width: 240,
      child: _MemberSnapshot(member: _selected!),
    );
  }

  bool isMobile() => MediaQuery.of(context).size.width < 700;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (e, _) => Center(child: ApexText('Error: $e', color: redAlert)),
        data: (members) {
          final mobile = isMobile();
          return SafeArea(
            child: mobile
                ? Column(
                    children: [
                      _buildMemberList(members, true),
                      const Divider(color: borderDark, height: 1),
                      Expanded(child: _buildCenterPanel()),
                      if (_selected != null)
                        SizedBox(height: 200, child: _buildRightPanel()),
                    ],
                  )
                : Row(
                    children: [
                      _buildMemberList(members, false),
                      VerticalDivider(width: 1, color: borderDark),
                      _buildCenterPanel(),
                      if (_selected != null)
                        const VerticalDivider(width: 1, color: borderDark),
                      if (_selected != null) _buildRightPanel(),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _AnalysisPanel extends StatelessWidget {
  final Member member;
  final int modeIdx;
  final bool loading;
  final String output;
  final ScrollController scrollCtrl;
  final VoidCallback onRun;
  final AiResponseKind? responseKind;
  final String? responseMessage;

  const _AnalysisPanel({
    required this.member,
    required this.modeIdx,
    required this.loading,
    required this.output,
    required this.scrollCtrl,
    required this.onRun,
    required this.responseKind,
    required this.responseMessage,
  });

  @override
  Widget build(BuildContext context) {
    final modeColor = [gold, redAlert, greenSuccess, blueInfo][modeIdx];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ApexText(
                      ['Coach Analysis', 'Churn Prediction', 'Nutrition AI', 'Chat'][modeIdx],
                      fontSize: 16,
                      color: modeColor,
                      fontWeight: FontWeight.w700,
                    ),
                    ApexText(
                      'for ${member.name}',
                      fontSize: 12,
                      color: const Color(0xFF555555),
                    ),
                  ],
                ),
              ),
              if (responseKind != null) _AiStatusPill(kind: responseKind!),
              if (!loading && output.isEmpty && responseKind != AiResponseKind.unavailable) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onRun,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [modeColor, modeColor.withOpacity(0.6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: modeColor.withOpacity(0.25), blurRadius: 12),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 14),
                        SizedBox(width: 6),
                        ApexText(
                          'Run AI',
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ApexCard(
              padding: const EdgeInsets.all(16),
              child: loading && output.isEmpty
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder(height: 14),
                        SizedBox(height: 10),
                        ShimmerPlaceholder(width: 300, height: 12),
                        SizedBox(height: 8),
                        ShimmerPlaceholder(height: 12),
                        SizedBox(height: 8),
                        ShimmerPlaceholder(width: 250, height: 12),
                        SizedBox(height: 24),
                        ShimmerPlaceholder(height: 14),
                        SizedBox(height: 10),
                        ShimmerPlaceholder(height: 12),
                      ],
                    )
                  : output.isEmpty
                      ? _EmptyAiState(
                          responseKind: responseKind,
                          responseMessage: responseMessage,
                          modeColor: modeColor,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (responseMessage != null &&
                                responseKind == AiResponseKind.demo) ...[
                              _AiNoticeBanner(
                                kind: responseKind!,
                                message: responseMessage!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollCtrl,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _MarkdownText(output),
                                    if (loading)
                                      Container(
                                        width: 8,
                                        height: 16,
                                        margin: const EdgeInsets.only(left: 2),
                                        color: modeColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStatusPill extends StatelessWidget {
  final AiResponseKind kind;

  const _AiStatusPill({required this.kind});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (kind) {
      case AiResponseKind.real:
        color = greenSuccess;
        label = 'LIVE';
        break;
      case AiResponseKind.demo:
        color = orangeWarning;
        label = 'DEMO ONLY';
        break;
      case AiResponseKind.unavailable:
        color = redAlert;
        label = 'UNAVAILABLE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: ApexText(
        label,
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _AiNoticeBanner extends StatelessWidget {
  final AiResponseKind kind;
  final String message;

  const _AiNoticeBanner({
    required this.kind,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = kind == AiResponseKind.demo ? orangeWarning : redAlert;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ApexText(
        message,
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EmptyAiState extends StatelessWidget {
  final AiResponseKind? responseKind;
  final String? responseMessage;
  final Color modeColor;

  const _EmptyAiState({
    required this.responseKind,
    required this.responseMessage,
    required this.modeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (responseKind == AiResponseKind.unavailable) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: redAlert, size: 40),
            const SizedBox(height: 12),
            ApexText(
              responseMessage ?? 'AI backend unavailable.',
              color: const Color(0xFFBBBBBB),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: modeColor.withOpacity(0.3),
            size: 40,
          ),
          const SizedBox(height: 12),
          const ApexText(
            'Press "Run AI" to generate analysis',
            color: Color(0xFF444444),
          ),
        ],
      ),
    );
  }
}

class _MarkdownText extends StatelessWidget {
  final String text;
  const _MarkdownText(this.text);

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('**') && line.endsWith('**')) {
          final clean = line.replaceAll('**', '');
          return Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: ApexText(
              clean,
              fontSize: 13,
              color: const Color(0xFFE8E8E8),
              fontWeight: FontWeight.w700,
            ),
          );
        }
        if (line.startsWith('• ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ApexText('• ', fontSize: 12, color: gold),
                Expanded(
                  child: ApexText(
                    line.substring(2),
                    fontSize: 12,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          );
        }
        return line.trim().isEmpty
            ? const SizedBox(height: 6)
            : Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ApexText(
                  line,
                  fontSize: 12,
                  color: const Color(0xFF888888),
                ),
              );
      }).toList(),
    );
  }
}

class _ChatPanel extends ConsumerWidget {
  final Member member;
  final TextEditingController chatCtrl;
  final Function(String) onSend;

  const _ChatPanel({
    required this.member,
    required this.chatCtrl,
    required this.onSend,
  });

  static const _quickQuestions = [
    'What should I eat today?',
    'Am I overtraining?',
    'Suggest a recovery day plan',
    'How do I break my plateau?',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider(member.id));

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF2A2A2A), size: 40),
                      const SizedBox(height: 8),
                      ApexText(
                        'Chat with APEX AI as ${member.name.split(' ').first}',
                        color: const Color(0xFF444444),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 8),
                        const ApexText(
                          'Debug builds may show DEMO ONLY responses if the backend is unavailable.',
                          fontSize: 10,
                          color: orangeWarning,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _quickQuestions
                            .map(
                              (q) => GestureDetector(
                                onTap: () => onSend(q),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: blueInfo.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: blueInfo.withOpacity(0.2)),
                                  ),
                                  child: ApexText(q, fontSize: 11, color: blueInfo),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    return _ChatBubble(msg: msg);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: borderDark)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatCtrl,
                  style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ask APEX AI…',
                    hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 13),
                    filled: true,
                    fillColor: cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: blueInfo),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: onSend,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onSend(chatCtrl.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: blueInfo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isDemoOnly = !msg.isUser && msg.text.startsWith('[DEMO ONLY]');
    final isUnavailable =
        !msg.isUser && msg.text.toLowerCase().contains('ai backend unavailable');

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: msg.isUser ? blueInfo.withOpacity(0.15) : cardDark,
          borderRadius: BorderRadius.circular(14).copyWith(
            bottomRight: msg.isUser ? Radius.zero : null,
            bottomLeft: msg.isUser ? null : Radius.zero,
          ),
          border: Border.all(
            color: msg.isUser ? blueInfo.withOpacity(0.25) : borderDark,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ApexText(
                      'APEX AI',
                      fontSize: 9,
                      color: blueInfo,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                    if (isDemoOnly) ...[
                      const SizedBox(width: 6),
                      const ApexText(
                        'DEMO ONLY',
                        fontSize: 9,
                        color: orangeWarning,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ],
                    if (isUnavailable) ...[
                      const SizedBox(width: 6),
                      const ApexText(
                        'UNAVAILABLE',
                        fontSize: 9,
                        color: redAlert,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ],
                  ],
                ),
              ),
            ApexText(
              msg.text.isEmpty ? '▋' : msg.text,
              fontSize: 12,
              color: const Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberSnapshot extends StatelessWidget {
  final Member member;
  const _MemberSnapshot({required this.member});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: avatarColor(member.av),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: ApexText(
                  member.av,
                  fontSize: 18,
                  color: const Color(0xFFE8E8E8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ApexText(
              member.name,
              fontSize: 13,
              color: const Color(0xFFDDDDDD),
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          _SnapRow('Goal', member.goal.replaceAll('_', ' ')),
          _SnapRow('Body Fat', '${member.bf}%'),
          _SnapRow('Streak', '🔥 ${member.streak}d'),
          _SnapRow('Sessions/mo', '${member.sessM}'),
          _SnapRow('Sub. Left', '${member.subLeft}d'),
          const SizedBox(height: 14),
          const ApexText(
            'LIFTS',
            fontSize: 9,
            color: Color(0xFF3A3A3A),
            letterSpacing: 1.5,
          ),
          const SizedBox(height: 8),
          ...member.lifts.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ApexText(
                          l.ex,
                          fontSize: 11,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      if (l.isStalled)
                        const ApexText(
                          'STALL',
                          fontSize: 9,
                          color: redAlert,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SparklineWidget(values: l.ws),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const ApexText(
            'NUTRITION',
            fontSize: 9,
            color: Color(0xFF3A3A3A),
            letterSpacing: 1.5,
          ),
          const SizedBox(height: 10),
          _NutRow('Calories', member.nut.ca, member.nut.ct, 'kcal', gold),
          const SizedBox(height: 8),
          _NutRow('Protein', member.nut.pa, member.nut.pt, 'g', blueInfo),
        ],
      ),
    );
  }
}

class _SnapRow extends StatelessWidget {
  final String label;
  final String value;
  const _SnapRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          ApexText(label, fontSize: 10, color: const Color(0xFF555555)),
          const Spacer(),
          ApexText(
            value,
            fontSize: 10,
            color: const Color(0xFFAAAAAA),
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

class _NutRow extends StatelessWidget {
  final String label;
  final double actual;
  final double target;
  final String unit;
  final Color color;
  const _NutRow(this.label, this.actual, this.target, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ApexText(label, fontSize: 10, color: const Color(0xFF666666)),
            const Spacer(),
            ApexText(
              '${actual.round()}/${target.round()} $unit',
              fontSize: 9,
              color: const Color(0xFF555555),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ApexProgressBar(value: actual, max: target, color: color, height: 3),
      ],
    );
  }
}
