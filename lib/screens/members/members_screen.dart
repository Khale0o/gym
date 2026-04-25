import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/core/helpers.dart';
import 'package:gymsaas/models/member.dart';
import 'package:gymsaas/providers/members_provider.dart';
import 'package:gymsaas/widgets/apex_text.dart';
import 'package:gymsaas/widgets/gold_heading.dart';
import 'package:gymsaas/widgets/apex_badge.dart';
import 'package:gymsaas/widgets/shimmer_placeholder.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(membersProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: bgDark,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GoldHeading('Members', fontSize: 18),
                const Spacer(),
                async.maybeWhen(
                  data: (list) => ApexText(
                    '${list.length} total',
                    fontSize: 12,
                    color: const Color(0xFF555555),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search members…',
                hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF444444), size: 18),
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
                  borderSide: const BorderSide(color: gold),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: async.when(
                loading: () => ListView.separated(
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, __) => const ShimmerCard(),
                ),
                error: (e, _) => Center(
                  child: ApexText('Error: $e', color: redAlert),
                ),
                data: (members) {
                  final filtered = _query.isEmpty
                      ? members
                      : members.where((m) => m.name.toLowerCase().contains(_query)).toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: ApexText('No members found', color: Color(0xFF444444)),
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MemberCard(member: filtered[i]),
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

class _MemberCard extends StatefulWidget {
  final Member member;
  const _MemberCard({required this.member});

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final risk = churnRisk(m);
    final rc = churnColor(risk);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/members/${m.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(isMobile ? 10 : 14),
          decoration: BoxDecoration(
            color: _hovered ? card2Dark : cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? gold.withOpacity(0.2) : borderDark,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 36 : 44,
                height: isMobile ? 36 : 44,
                decoration: BoxDecoration(
                  color: avatarColor(m.av),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: ApexText(m.av, fontSize: isMobile ? 12 : 14,
                      color: const Color(0xFFE8E8E8), fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ApexText(m.name, fontSize: isMobile ? 12 : 13,
                              color: const Color(0xFFDDDDDD), fontWeight: FontWeight.w600),
                        ),
                        if (m.streak > 0)
                          ApexText('🔥 ${m.streak}', fontSize: isMobile ? 10 : 11),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ApexText(m.last, fontSize: isMobile ? 10 : 11,
                        color: const Color(0xFF555555)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isMobile) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ApexBadge(
                          text: m.plan,
                          color: m.plan == 'Elite' ? gold : m.plan == 'Premium' ? blueInfo : const Color(0xFF555555),
                        ),
                        const SizedBox(width: 6),
                        ApexBadge(
                          text: m.status,
                          color: m.status == 'active' ? greenSuccess : redAlert,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(color: rc, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        ApexText('${risk[0].toUpperCase()}${risk.substring(1)} risk',
                            fontSize: 10, color: rc),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right_rounded,
                  color: const Color(0xFF333333), size: isMobile ? 16 : 18),
            ],
          ),
        ),
      ),
    );
  }
}