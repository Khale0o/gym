import 'package:cloud_firestore/cloud_firestore.dart';

class GymFirestorePaths {
  GymFirestorePaths(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> gymDoc(String gymId) {
    return _db.collection('gyms').doc(gymId);
  }

  CollectionReference<Map<String, dynamic>> membersCollection(String gymId) {
    return gymDoc(gymId).collection('members');
  }

  DocumentReference<Map<String, dynamic>> memberDoc(
    String gymId,
    String memberId,
  ) {
    return membersCollection(gymId).doc(memberId);
  }

  CollectionReference<Map<String, dynamic>> memberInvitesCollection(
    String gymId,
  ) {
    return gymDoc(gymId).collection('memberInvites');
  }

  DocumentReference<Map<String, dynamic>> memberInviteDoc(
    String gymId,
    String inviteId,
  ) {
    return memberInvitesCollection(gymId).doc(inviteId);
  }

  CollectionReference<Map<String, dynamic>> staffCollection(String gymId) {
    return gymDoc(gymId).collection('staff');
  }

  CollectionReference<Map<String, dynamic>> staffInvitesCollection(
    String gymId,
  ) {
    return gymDoc(gymId).collection('staffInvites');
  }

  DocumentReference<Map<String, dynamic>> staffInviteDoc(
    String gymId,
    String inviteId,
  ) {
    return staffInvitesCollection(gymId).doc(inviteId);
  }

  DocumentReference<Map<String, dynamic>> staffDoc(
    String gymId,
    String staffId,
  ) {
    return staffCollection(gymId).doc(staffId);
  }

  CollectionReference<Map<String, dynamic>> plansCollection(String gymId) {
    return gymDoc(gymId).collection('plans');
  }

  DocumentReference<Map<String, dynamic>> planDoc(
    String gymId,
    String planId,
  ) {
    return plansCollection(gymId).doc(planId);
  }

  CollectionReference<Map<String, dynamic>> subscriptionsCollection(
    String gymId,
  ) {
    return gymDoc(gymId).collection('subscriptions');
  }

  DocumentReference<Map<String, dynamic>> subscriptionDoc(
    String gymId,
    String subscriptionId,
  ) {
    return subscriptionsCollection(gymId).doc(subscriptionId);
  }

  CollectionReference<Map<String, dynamic>> checkinsCollection(String gymId) {
    return gymDoc(gymId).collection('checkins');
  }

  CollectionReference<Map<String, dynamic>> transactionsCollection(
    String gymId,
  ) {
    return gymDoc(gymId).collection('transactions');
  }

  CollectionReference<Map<String, dynamic>> productsCollection(String gymId) {
    return gymDoc(gymId).collection('products');
  }

  CollectionReference<Map<String, dynamic>> shiftsCollection(String gymId) {
    return gymDoc(gymId).collection('shifts');
  }

  DocumentReference<Map<String, dynamic>> occupancyDoc(String gymId) {
    return settingsCollection(gymId).doc('occupancy');
  }

  CollectionReference<Map<String, dynamic>> settingsCollection(String gymId) {
    return gymDoc(gymId).collection('settings');
  }
}
