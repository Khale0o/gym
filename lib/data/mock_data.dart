import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gymsaas/models/member.dart';

/// Seeds all Firestore collections with demo data.
///
/// Development only:
/// - never call this automatically from normal UI flow
/// - never expose this in release mode
Future<void> seedFirestore(String gymId) async {
  if (!kDebugMode) {
    throw StateError('Demo seeding is disabled outside debug mode.');
  }
  final trimmedGymId = gymId.trim();
  if (trimmedGymId.isEmpty) {
    throw StateError('Demo seeding requires a gymId.');
  }

  final db = FirebaseFirestore.instance;
  final gymRef = db.collection('gyms').doc(trimmedGymId);

  await gymRef.collection('settings').doc('occupancy').set({
    'count': 23,
    'capacity': 60,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  final plans = [
    {'name': 'Basic', 'price': 150, 'membersCount': 68},
    {'name': 'Premium', 'price': 280, 'membersCount': 51},
    {'name': 'Elite', 'price': 420, 'membersCount': 23},
  ];
  for (final p in plans) {
    await gymRef.collection('plans').add({
      ...p,
      'gymId': trimmedGymId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  final members = _buildMembers();
  final Map<String, String> memberIdByName = {};
  for (final m in members) {
    final ref = await gymRef.collection('members').add({
      ...m.toMap(),
      'gymId': trimmedGymId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    memberIdByName[m.name] = ref.id;
  }

  final now = DateTime.now();
  final checkInNames = [
    'Ahmed K.',
    'Sara M.',
    'Karim A.',
    'Lena R.',
    'Omar F.',
    'Nora S.',
    'Yusuf T.',
    'Mia P.',
  ];
  final methods = ['NFC', 'QR', 'Manual'];
  final ciPlans = ['Basic', 'Premium', 'Elite'];
  for (var i = 0; i < 8; i++) {
    await gymRef.collection('checkins').add({
      'gymId': trimmedGymId,
      'memberId': memberIdByName.values.elementAt(i % memberIdByName.length),
      'name': checkInNames[i % checkInNames.length],
      'time': Timestamp.fromDate(now.subtract(Duration(minutes: i * 12))),
      'method': methods[i % 3],
      'plan': ciPlans[i % 3],
    });
  }

  final txData = [
    {'category': 'Membership Renewals', 'amount': 8400, 'type': 'income'},
    {'category': 'Personal Training', 'amount': 3200, 'type': 'income'},
    {'category': 'Supplement Sales', 'amount': 1600, 'type': 'income'},
    {'category': 'Staff Salaries', 'amount': 12000, 'type': 'expense'},
    {'category': 'Equipment Maintenance', 'amount': 2200, 'type': 'expense'},
    {'category': 'Utilities', 'amount': 1800, 'type': 'expense'},
    {'category': 'New Equipment', 'amount': 5400, 'type': 'expense'},
    {'category': 'Walk-in Fees', 'amount': 950, 'type': 'income'},
  ];
  for (var i = 0; i < txData.length; i++) {
    await gymRef.collection('transactions').add({
      ...txData[i],
      'gymId': trimmedGymId,
      'date': Timestamp.fromDate(now.subtract(Duration(days: i * 3))),
      'createdAt': Timestamp.fromDate(now.subtract(Duration(days: i * 3))),
    });
  }

  final staffData = [
    {'name': 'Coach Tarek', 'role': 'Head Trainer', 'onDuty': true},
    {'name': 'Hana Adel', 'role': 'Receptionist', 'onDuty': true},
    {'name': 'Mostafa B.', 'role': 'Trainer', 'onDuty': true},
    {'name': 'Rana K.', 'role': 'Nutritionist', 'onDuty': false},
    {'name': 'Sayed A.', 'role': 'Maintenance', 'onDuty': true},
    {'name': 'Dina F.', 'role': 'Trainer', 'onDuty': true},
    {'name': 'Khaled M.', 'role': 'Security', 'onDuty': false},
    {'name': 'Nadia R.', 'role': 'Trainer', 'onDuty': false},
    {'name': 'Amr G.', 'role': 'Cleaner', 'onDuty': true},
  ];
  for (final s in staffData) {
    await gymRef.collection('staff').add({
      ...s,
      'gymId': trimmedGymId,
      'fullName': s['name'],
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

List<Member> _buildMembers() => [
      Member(
        id: '',
        name: 'Ahmed Khalil',
        plan: 'Elite',
        status: 'active',
        sessions: 42,
        streak: 7,
        av: 'AK',
        last: '2h ago',
        w: 82,
        tag: 'NFC',
        age: 28,
        height: 178,
        goal: 'muscle_gain',
        months: 14,
        att: 0.88,
        sessM: 12,
        sessLM: 14,
        bf: 14.2,
        mm: 68.4,
        injuries: [],
        ptime: 'morning',
        neglect: ['Legs'],
        lifts: [
          Lift(ex: 'Bench Press', ws: [80, 82.5, 85, 85, 87.5, 90]),
          Lift(ex: 'Squat', ws: [100, 105, 107.5, 110, 110, 112.5]),
          Lift(ex: 'Deadlift', ws: [120, 125, 130, 132.5, 135, 140]),
        ],
        nut: const Nutrition(ct: 2800, ca: 2650, pt: 180, pa: 162),
        subLeft: 22,
        lastDays: 0,
      ),
      Member(
        id: '',
        name: 'Sara Mohamed',
        plan: 'Premium',
        status: 'active',
        sessions: 31,
        streak: 4,
        av: 'SM',
        last: '1d ago',
        w: 58,
        tag: 'QR',
        age: 24,
        height: 162,
        goal: 'weight_loss',
        months: 6,
        att: 0.72,
        sessM: 8,
        sessLM: 11,
        bf: 22.1,
        mm: 42.3,
        injuries: ['Lower Back'],
        ptime: 'afternoon',
        neglect: ['Core'],
        lifts: [
          Lift(ex: 'Hip Thrust', ws: [60, 65, 70, 72.5, 72.5, 72.5]),
          Lift(ex: 'Leg Press', ws: [80, 85, 90, 90, 95, 100]),
        ],
        nut: const Nutrition(ct: 1800, ca: 1620, pt: 130, pa: 98),
        subLeft: 14,
        lastDays: 1,
      ),
      Member(
        id: '',
        name: 'Karim Amir',
        plan: 'Basic',
        status: 'active',
        sessions: 18,
        streak: 2,
        av: 'KA',
        last: '3d ago',
        w: 91,
        tag: null,
        age: 33,
        height: 182,
        goal: 'general_fitness',
        months: 3,
        att: 0.55,
        sessM: 5,
        sessLM: 9,
        bf: 26.8,
        mm: 61.2,
        injuries: ['Shoulder Impingement'],
        ptime: 'evening',
        neglect: ['Cardio', 'Flexibility'],
        lifts: [
          Lift(ex: 'Bench Press', ws: [70, 72.5, 75, 75, 75, 75]),
          Lift(ex: 'Lat Pulldown', ws: [55, 57.5, 60, 60, 60, 62.5]),
        ],
        nut: const Nutrition(ct: 2400, ca: 2800, pt: 160, pa: 95),
        subLeft: 5,
        lastDays: 3,
      ),
      Member(
        id: '',
        name: 'Lena Ramzy',
        plan: 'Elite',
        status: 'active',
        sessions: 56,
        streak: 14,
        av: 'LR',
        last: '4h ago',
        w: 62,
        tag: 'NFC',
        age: 26,
        height: 168,
        goal: 'muscle_gain',
        months: 22,
        att: 0.94,
        sessM: 16,
        sessLM: 15,
        bf: 18.4,
        mm: 48.6,
        injuries: [],
        ptime: 'morning',
        neglect: [],
        lifts: [
          Lift(ex: 'Romanian Deadlift', ws: [70, 75, 80, 82.5, 85, 87.5]),
          Lift(ex: 'Overhead Press', ws: [35, 37.5, 40, 42.5, 45, 47.5]),
          Lift(ex: 'Pull-ups', ws: [0, 0, 2.5, 5, 7.5, 10]),
        ],
        nut: const Nutrition(ct: 2200, ca: 2190, pt: 155, pa: 148),
        subLeft: 38,
        lastDays: 0,
      ),
      Member(
        id: '',
        name: 'Omar Fathi',
        plan: 'Premium',
        status: 'active',
        sessions: 27,
        streak: 0,
        av: 'OF',
        last: '6d ago',
        w: 78,
        tag: 'QR',
        age: 31,
        height: 175,
        goal: 'weight_loss',
        months: 8,
        att: 0.58,
        sessM: 4,
        sessLM: 10,
        bf: 23.5,
        mm: 55.8,
        injuries: [],
        ptime: 'evening',
        neglect: ['Upper Back', 'Arms'],
        lifts: [
          Lift(ex: 'Treadmill 10k', ws: [58, 56, 54, 53, 53, 53]),
          Lift(ex: 'Rowing Machine', ws: [45, 47, 50, 50, 50, 50]),
        ],
        nut: const Nutrition(ct: 2000, ca: 2400, pt: 140, pa: 88),
        subLeft: 18,
        lastDays: 6,
      ),
      Member(
        id: '',
        name: 'Nora Saleh',
        plan: 'Basic',
        status: 'inactive',
        sessions: 9,
        streak: 0,
        av: 'NS',
        last: '12d ago',
        w: 66,
        tag: null,
        age: 29,
        height: 165,
        goal: 'general_fitness',
        months: 2,
        att: 0.42,
        sessM: 2,
        sessLM: 5,
        bf: 28.2,
        mm: 38.9,
        injuries: ['Knee Pain'],
        ptime: 'afternoon',
        neglect: ['Lower Body'],
        lifts: [
          Lift(ex: 'Walking Lunges', ws: [20, 20, 22.5, 22.5, 22.5, 22.5]),
        ],
        nut: const Nutrition(ct: 1700, ca: 1900, pt: 110, pa: 62),
        subLeft: 2,
        lastDays: 12,
      ),
      Member(
        id: '',
        name: 'Yusuf Tamer',
        plan: 'Elite',
        status: 'active',
        sessions: 61,
        streak: 21,
        av: 'YT',
        last: '1h ago',
        w: 88,
        tag: 'NFC',
        age: 25,
        height: 183,
        goal: 'muscle_gain',
        months: 18,
        att: 0.96,
        sessM: 18,
        sessLM: 17,
        bf: 11.8,
        mm: 73.2,
        injuries: [],
        ptime: 'morning',
        neglect: [],
        lifts: [
          Lift(ex: 'Bench Press', ws: [110, 115, 117.5, 120, 122.5, 125]),
          Lift(ex: 'Squat', ws: [150, 155, 160, 162.5, 165, 170]),
          Lift(ex: 'Deadlift', ws: [180, 185, 190, 195, 200, 205]),
        ],
        nut: const Nutrition(ct: 3200, ca: 3180, pt: 210, pa: 205),
        subLeft: 44,
        lastDays: 0,
      ),
      Member(
        id: '',
        name: 'Mia Petros',
        plan: 'Premium',
        status: 'active',
        sessions: 34,
        streak: 5,
        av: 'MP',
        last: '2d ago',
        w: 54,
        tag: 'QR',
        age: 22,
        height: 158,
        goal: 'weight_loss',
        months: 5,
        att: 0.78,
        sessM: 10,
        sessLM: 10,
        bf: 24.6,
        mm: 36.4,
        injuries: [],
        ptime: 'afternoon',
        neglect: ['Shoulders'],
        lifts: [
          Lift(ex: 'Cable Fly', ws: [15, 17.5, 20, 22.5, 25, 27.5]),
          Lift(ex: 'Leg Curl', ws: [30, 32.5, 35, 37.5, 37.5, 40]),
        ],
        nut: const Nutrition(ct: 1600, ca: 1550, pt: 115, pa: 108),
        subLeft: 27,
        lastDays: 2,
      ),
    ];
