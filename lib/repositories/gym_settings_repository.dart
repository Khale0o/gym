import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsaas/models/gym_settings.dart';
import 'package:gymsaas/services/gym_firestore_paths.dart';

class GymSettingsRepository {
  GymSettingsRepository(this._paths);

  final GymFirestorePaths _paths;

  Stream<GymProfileSettings> streamGymProfile(String gymId) {
    return _paths.gymDoc(gymId).snapshots().map(GymProfileSettings.fromFirestore);
  }

  Stream<OccupancySettings> streamOccupancySettings(String gymId) {
    return _paths
        .occupancyDoc(gymId)
        .snapshots()
        .map(OccupancySettings.fromFirestore);
  }

  Stream<AppSettings> streamAppSettings(String gymId) {
    return _paths.appSettingsDoc(gymId).snapshots().map(AppSettings.fromFirestore);
  }

  Future<void> updateGymProfile({
    required String gymId,
    required String updatedBy,
    required Map<String, dynamic> data,
  }) {
    return _paths.gymDoc(gymId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    }, SetOptions(merge: true));
  }

  Future<void> updateOccupancySettings({
    required String gymId,
    required String updatedBy,
    required int capacity,
  }) {
    if (capacity < 0) {
      throw StateError('Capacity must be zero or greater.');
    }

    return _paths.occupancyDoc(gymId).set({
      'capacity': capacity,
      'maxCapacity': capacity,
      'count': FieldValue.increment(0),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    }, SetOptions(merge: true));
  }

  Future<void> updateAppSettings({
    required String gymId,
    required String updatedBy,
    required AppSettingsUpdate input,
  }) {
    return _paths.appSettingsDoc(gymId).set({
      'allowPartialPayments': input.allowPartialPayments,
      'expiringSoonDays': input.expiringSoonDays,
      'checkInRequiresPaidOrPartial': input.checkInRequiresPaidOrPartial,
      'defaultReceiptPrefix': input.defaultReceiptPrefix,
      'enabledPaymentMethods': input.enabledPaymentMethods,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    }, SetOptions(merge: true));
  }
}

class AppSettingsUpdate {
  const AppSettingsUpdate({
    required this.allowPartialPayments,
    required this.expiringSoonDays,
    required this.checkInRequiresPaidOrPartial,
    required this.defaultReceiptPrefix,
    required this.enabledPaymentMethods,
  });

  final bool allowPartialPayments;
  final int expiringSoonDays;
  final bool checkInRequiresPaidOrPartial;
  final String defaultReceiptPrefix;
  final List<String> enabledPaymentMethods;
}
