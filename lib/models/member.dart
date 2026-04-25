import 'package:cloud_firestore/cloud_firestore.dart';

class Nutrition {
  final double ct; // calorie target
  final double ca; // calorie actual
  final double pt; // protein target (g)
  final double pa; // protein actual (g)

  const Nutrition({
    required this.ct,
    required this.ca,
    required this.pt,
    required this.pa,
  });

  factory Nutrition.fromMap(Map<String, dynamic> m) => Nutrition(
        ct: (m['ct'] ?? 2000).toDouble(),
        ca: (m['ca'] ?? 0).toDouble(),
        pt: (m['pt'] ?? 150).toDouble(),
        pa: (m['pa'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'ct': ct,
        'ca': ca,
        'pt': pt,
        'pa': pa,
      };
}

class Lift {
  final String ex; // exercise name
  final List<double> ws; // 6-week weight progression

  const Lift({required this.ex, required this.ws});

  factory Lift.fromMap(Map<String, dynamic> m) => Lift(
        ex: m['ex'] ?? '',
        ws: List<double>.from(
          (m['ws'] ?? <dynamic>[]).map((e) => (e as num).toDouble()),
        ),
      );

  Map<String, dynamic> toMap() => {'ex': ex, 'ws': ws};

  bool get isStalled =>
      ws.length >= 3 &&
      ws[ws.length - 1] == ws[ws.length - 2] &&
      ws[ws.length - 2] == ws[ws.length - 3];
}

class Member {
  final String id;
  final String name;
  final String plan;
  final String status; // active / inactive / frozen
  final int sessions;
  final int streak;
  final String av; // initials avatar
  final String last; // last seen text
  final double w; // weight kg
  final String? tag; // NFC / QR / null
  final int age;
  final double height;
  final String goal; // muscle_gain / weight_loss / general_fitness
  final int months;
  final double att; // attendance ratio 0-1
  final int sessM; // sessions this month
  final int sessLM; // sessions last month
  final double bf; // body fat %
  final double mm; // muscle mass kg
  final List<String> injuries;
  final String ptime; // morning / afternoon / evening
  final List<String> neglect; // neglected muscle groups
  final List<Lift> lifts;
  final Nutrition nut;
  final int subLeft; // subscription days left
  final int lastDays; // days since last visit

  const Member({
    required this.id,
    required this.name,
    required this.plan,
    required this.status,
    required this.sessions,
    required this.streak,
    required this.av,
    required this.last,
    required this.w,
    this.tag,
    required this.age,
    required this.height,
    required this.goal,
    required this.months,
    required this.att,
    required this.sessM,
    required this.sessLM,
    required this.bf,
    required this.mm,
    required this.injuries,
    required this.ptime,
    required this.neglect,
    required this.lifts,
    required this.nut,
    required this.subLeft,
    required this.lastDays,
  });

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      name: m['name'] ?? '',
      plan: m['plan'] ?? 'Basic',
      status: m['status'] ?? 'active',
      sessions: (m['sessions'] ?? 0) as int,
      streak: (m['streak'] ?? 0) as int,
      av: m['av'] ?? '',
      last: m['last'] ?? '',
      w: (m['w'] ?? 70).toDouble(),
      tag: m['tag'] as String?,
      age: (m['age'] ?? 25) as int,
      height: (m['height'] ?? 170).toDouble(),
      goal: m['goal'] ?? 'general_fitness',
      months: (m['months'] ?? 1) as int,
      att: (m['att'] ?? 0.8).toDouble(),
      sessM: (m['sessM'] ?? 8) as int,
      sessLM: (m['sessLM'] ?? 10) as int,
      bf: (m['bf'] ?? 20).toDouble(),
      mm: (m['mm'] ?? 50).toDouble(),
      injuries: List<String>.from(m['injuries'] ?? []),
      ptime: m['ptime'] ?? 'morning',
      neglect: List<String>.from(m['neglect'] ?? []),
      lifts: ((m['lifts'] ?? <dynamic>[]) as List)
          .map((l) => Lift.fromMap(l as Map<String, dynamic>))
          .toList(),
      nut: Nutrition.fromMap((m['nut'] ?? {}) as Map<String, dynamic>),
      subLeft: (m['subLeft'] ?? 30) as int,
      lastDays: (m['lastDays'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'plan': plan,
        'status': status,
        'sessions': sessions,
        'streak': streak,
        'av': av,
        'last': last,
        'w': w,
        'tag': tag,
        'age': age,
        'height': height,
        'goal': goal,
        'months': months,
        'att': att,
        'sessM': sessM,
        'sessLM': sessLM,
        'bf': bf,
        'mm': mm,
        'injuries': injuries,
        'ptime': ptime,
        'neglect': neglect,
        'lifts': lifts.map((l) => l.toMap()).toList(),
        'nut': nut.toMap(),
        'subLeft': subLeft,
        'lastDays': lastDays,
      };
}
