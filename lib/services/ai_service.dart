import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gymsaas/models/member.dart';

/// Endpoint of your deployed Firebase Cloud Function.
/// Replace with your real URL after deploying.
const String _kFunctionUrl =
    'https://us-central1-apex-gym-system.cloudfunctions.net/aiAnalyze';

enum AiResponseKind {
  real,
  demo,
  unavailable,
}

class AiResponseEvent {
  final AiResponseKind kind;
  final String? textChunk;
  final String? message;

  const AiResponseEvent({
    required this.kind,
    this.textChunk,
    this.message,
  });
}

class AiService {
  /// Streams AI response events for a given [mode] and [member].
  ///
  /// Real backend responses are marked as [AiResponseKind.real].
  /// Demo output is only allowed in debug mode and is marked as
  /// [AiResponseKind.demo].
  /// Backend failures without demo mode return
  /// [AiResponseKind.unavailable].
  Stream<AiResponseEvent> analyze({
    required Member member,
    required String mode, // coach | churn | nutrition | chat
    String? userMessage,
    bool allowDemoFallback = false,
  }) async* {
    try {
      final request = http.Request('POST', Uri.parse(_kFunctionUrl));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'memberId': member.id,
        'mode': mode,
        if (userMessage != null) 'message': userMessage,
      });

      final response =
          await request.send().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        yield const AiResponseEvent(kind: AiResponseKind.real);
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          yield AiResponseEvent(
            kind: AiResponseKind.real,
            textChunk: chunk,
          );
        }
        return;
      }

      if (allowDemoFallback && kDebugMode) {
        yield const AiResponseEvent(
          kind: AiResponseKind.demo,
          message: 'DEMO ONLY: local mock output, not a real backend response.',
        );
        yield* _mockStream(member, mode);
        return;
      }

      yield AiResponseEvent(
        kind: AiResponseKind.unavailable,
        message:
            'AI backend unavailable. Cloud Function returned status ${response.statusCode}.',
      );
    } catch (_) {
      if (allowDemoFallback && kDebugMode) {
        yield const AiResponseEvent(
          kind: AiResponseKind.demo,
          message: 'DEMO ONLY: local mock output, not a real backend response.',
        );
        yield* _mockStream(member, mode);
        return;
      }

      yield const AiResponseEvent(
        kind: AiResponseKind.unavailable,
        message:
            'AI backend unavailable. Please try again later or verify the Cloud Function deployment.',
      );
    }
  }

  Stream<AiResponseEvent> _mockStream(Member member, String mode) async* {
    final text = _mockResponse(member, mode);
    final words = text.split(' ');
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 40));
      yield AiResponseEvent(
        kind: AiResponseKind.demo,
        textChunk: '$word ',
      );
    }
  }

  String _mockResponse(Member member, String mode) {
    switch (mode) {
      case 'coach':
        return '''**APEX AI Coach Assessment — ${member.name}**

**Current Status:** ${member.goal.replaceAll('_', ' ').toUpperCase()} | ${member.sessM} sessions this month vs ${member.sessLM} last month.

**Strengths:** Consistent attendance at ${(member.att * 100).round()}% and a ${member.streak}-day streak show solid dedication.

**Areas of Concern:** ${member.neglect.isEmpty ? 'No major gaps identified.' : 'Neglected areas: ${member.neglect.join(', ')}'} ${member.injuries.isEmpty ? '' : 'Injuries noted: ${member.injuries.join(', ')} — modify accordingly.'}

**4-Week Program:**
• Week 1–2: Foundation — 4×8 compound lifts at 70% 1RM
• Week 3: Progressive overload — increase 2.5–5 kg on main lifts
• Week 4: Deload — 3×6 at 60% to allow recovery

**Recovery Protocol:** 7–9h sleep, foam roll post-session, cold contrast showers 3×/week.

Train smart. Train APEX.''';

      case 'churn':
        final riskScore = member.att < 0.6
            ? 78
            : member.sessM < member.sessLM * 0.6
                ? 65
                : 24;
        return '''**CHURN RISK SCORE: $riskScore / 100**

**Risk Level:** ${riskScore > 60 ? 'HIGH' : riskScore > 40 ? 'MEDIUM' : 'LOW'}

**Risk Signals Detected:**
• Session frequency: ${member.sessM} this month vs ${member.sessLM} last month (${((1 - member.sessM / (member.sessLM == 0 ? 1 : member.sessLM)) * 100).round()}% drop)
• Last visit: ${member.lastDays} day(s) ago
• Subscription: ${member.subLeft} days remaining
• Attendance rate: ${(member.att * 100).round()}%

**Recommended Retention Message:**
"Hey ${member.name.split(' ').first}! We noticed you haven't been in lately — your gains are waiting! Book a free session with Coach Tarek this week. Special renewal offer: 15% off your next ${member.plan} plan."

**Action Items:** Personal outreach call, free PT session, renewal discount.''';

      case 'nutrition':
        final calGap = member.nut.ct - member.nut.ca;
        final protGap = member.nut.pt - member.nut.pa;
        return '''**APEX Nutrition AI — ${member.name}**

**Gap Analysis:**
• Calorie gap: ${calGap.abs().round()} kcal ${calGap > 0 ? 'under' : 'over'} target
• Protein gap: ${protGap.abs().round()} g ${protGap > 0 ? 'under' : 'over'} target

**Recalculated Macros (based on ${member.bf}% BF, ${member.mm} kg LBM):**
• Calories: ${(member.nut.ct * 1.02).round()} kcal
• Protein: ${(member.mm * 2.2).round()} g
• Carbs: ${((member.nut.ct * 0.45) / 4).round()} g
• Fat: ${((member.nut.ct * 0.25) / 9).round()} g

**Meal Timing:**
• Pre-workout (90 min before): 40g carbs + 20g protein
• Post-workout (within 45 min): 50g carbs + 30g protein
• Pre-sleep: 30g casein protein

**Supplements:** Creatine 5g/day, Vitamin D3 4000 IU, Magnesium 400mg (sleep).''';

      default:
        return 'Hello ${member.name.split(' ').first}! I\'m APEX AI. How can I help you today?';
    }
  }
}
