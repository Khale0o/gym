import 'package:cloud_firestore/cloud_firestore.dart';

String friendlyFirestoreErrorMessage(
  Object error, {
  String fallback = 'Could not load this data.',
}) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to access this data. Your account may be inactive or not linked to this gym. Please contact the gym owner/admin.';
      case 'failed-precondition':
        return 'This data needs a Firestore index before it can load.';
      case 'unavailable':
        return 'Firestore is unavailable right now. Please try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? fallback;
    }
  }

  final message = error.toString().replaceFirst('Bad state: ', '');
  final lower = message.toLowerCase();
  if (lower.contains('permission-denied')) {
    return 'You do not have permission to access this data. Your account may be inactive or not linked to this gym. Please contact the gym owner/admin.';
  }
  if (lower.contains('failed-precondition') || lower.contains('index')) {
    return 'This data needs a Firestore index before it can load.';
  }
  if (lower.contains('unavailable') || lower.contains('network')) {
    return 'Network error. Check your connection and try again.';
  }
  if (lower.contains('no current gym') || lower.contains('missing gym')) {
    return 'No current gym is selected for this account.';
  }
  return message.isEmpty ? fallback : message;
}
