import 'dart:async';

import 'package:birthday_reminder/models/birthday.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _writeConfirmationTimeout = Duration(seconds: 5);

class BirthdayRepository {
  BirthdayRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('birthdays');

  Stream<List<Birthday>> watchBirthdays() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error(StateError('Sign in to load birthdays.'));
    }
    return _collection
        .where('owner', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final birthdays = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        final birth = data['birth'];
        if (birth is Timestamp) data['birth'] = birth.toDate();
        return Birthday.fromMap(data, id: doc.id);
      }).toList();
      final reference = DateTime.now();
      final daysUntil = {
        for (final birthday in birthdays)
          birthday.id: birthday.durationToNextBirthday(from: reference),
      };
      birthdays.sort(
        (a, b) => daysUntil[a.id]!.compareTo(daysUntil[b.id]!),
      );
      return birthdays;
    });
  }

  String newBirthdayId() => _collection.doc().id;

  Future<Birthday> create(Birthday birthday, {required String id}) async {
    final user = _requireUser();
    final now = DateTime.now();
    final data = birthday.toMap(owner: user.uid, now: now);
    data['created_at'] = now;
    try {
      await _collection.doc(id).set(data).timeout(_writeConfirmationTimeout);
    } on TimeoutException {
      throw BirthdayWriteTimeoutException(id);
    }
    return birthday.copyWith(id: id);
  }

  Future<void> update(Birthday birthday) async {
    final user = _requireUser();
    try {
      await _collection
          .doc(birthday.id)
          .update(birthday.toMap(owner: user.uid, now: DateTime.now()))
          .timeout(_writeConfirmationTimeout);
    } on TimeoutException {
      throw BirthdayWriteTimeoutException(birthday.id);
    }
  }

  Future<void> delete(String id) async {
    _requireUser();
    await _collection.doc(id).delete();
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to manage birthdays.');
    return user;
  }
}

class BirthdayWriteTimeoutException implements Exception {
  const BirthdayWriteTimeoutException(this.birthdayId);

  final String birthdayId;
}
