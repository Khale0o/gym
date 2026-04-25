import 'package:gymsaas/models/member.dart';

const String sysCOACH =
    'You are APEX AI — an elite personal trainer and strength coach with 20 years of experience. '
    'Give honest, science-based assessments. Be direct and specific. '
    'Format your response with markdown bold headers.';

const String sysCHURN =
    'You are APEX Churn Intelligence — a retention analytics engine. '
    'Analyze member behavior data and output a churn risk score 0-100, '
    'key risk signals, and a personalized retention message. '
    'Format with markdown bold headers.';

const String sysNUT =
    'You are APEX Nutrition AI — a certified sports dietitian and nutritionist. '
    'Analyze body composition and tracking data to provide precise macro targets, '
    'meal timing strategies, and supplement recommendations. '
    'Format with markdown bold headers.';

String sysCHAT(String memberName) =>
    'You are APEX AI — a friendly, knowledgeable fitness assistant talking directly '
    'to $memberName. Keep responses concise, motivating, and actionable. '
    'Be warm but professional.';

String buildCoachPrompt(Member m) => '''
Member Profile:
- Name: ${m.name} | Age: ${m.age} | Height: ${m.height}cm | Weight: ${m.w}kg
- Goal: ${m.goal.replaceAll('_', ' ')} | Plan: ${m.plan} | Months active: ${m.months}
- Body Fat: ${m.bf}% | Muscle Mass: ${m.mm}kg
- Sessions this month: ${m.sessM} (last month: ${m.sessLM})
- Attendance rate: ${(m.att * 100).round()}% | Streak: ${m.streak} days
- Preferred time: ${m.ptime}
- Injuries: ${m.injuries.isEmpty ? 'None' : m.injuries.join(', ')}
- Neglected muscle groups: ${m.neglect.isEmpty ? 'None identified' : m.neglect.join(', ')}
- Lift progression (last 6 weeks):
${m.lifts.map((l) => '  • ${l.ex}: ${l.ws.join(' → ')} kg${l.isStalled ? ' ⚠ STALLED' : ''}').join('\n')}

Provide: honest assessment, 4-week training program, recovery protocol.
''';

String buildChurnPrompt(Member m) => '''
Member Retention Analysis:
- Name: ${m.name} | Plan: ${m.plan} | Active months: ${m.months}
- Sessions this month: ${m.sessM} | Last month: ${m.sessLM}
- Attendance: ${(m.att * 100).round()}% | Last visit: ${m.lastDays} day(s) ago
- Subscription days left: ${m.subLeft}
- Calorie tracking adherence: ${m.nut.ca > 0 ? 'Active' : 'Not tracking'}

Provide: churn score (0-100), risk signals, personalized retention message.
''';

String buildNutPrompt(Member m) => '''
Nutrition Analysis Request:
- Name: ${m.name} | Age: ${m.age} | Weight: ${m.w}kg | Height: ${m.height}cm
- Body Fat: ${m.bf}% | Lean Mass: ${m.mm}kg
- Goal: ${m.goal.replaceAll('_', ' ')}
- Calorie target: ${m.nut.ct} kcal | Actual: ${m.nut.ca} kcal
- Protein target: ${m.nut.pt}g | Actual: ${m.nut.pa}g
- Training load: ${m.sessM} sessions/month at ${m.ptime}
- Injuries: ${m.injuries.isEmpty ? 'None' : m.injuries.join(', ')}

Provide: gap analysis, recalculated macros, meal timing, supplement stack.
''';
