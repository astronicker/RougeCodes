import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/batch_models.dart';

class BatchService {
  BatchService._();

  static final BatchService instance = BatchService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _batches =>
      _db.collection('batches');
  CollectionReference<Map<String, dynamic>> get _enrollments =>
      _db.collection('batch_enrollments');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<List<BatchItem>> watchBatches() {
    return _batches
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(BatchItem.fromDoc).toList());
  }

  Future<List<BatchItem>> fetchBatches() async {
    final snapshot = await _batches
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(BatchItem.fromDoc).toList();
  }

  Future<void> createBatch({
    required String name,
    required List<String> days,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final startAt = _nextOccurrence(days: days, time: startTime);
    var endAt = DateTime(
      startAt.year,
      startAt.month,
      startAt.day,
      endTime.hour,
      endTime.minute,
    );

    if (endAt.isBefore(startAt)) {
      endAt = endAt.add(const Duration(days: 1));
    }

    await _batches.add({
      'name': name.trim(),
      'days': days,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'schedule': _buildSchedule(days, startTime, endTime),
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'enrollmentCount': 0,
      'resources': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBatch(String batchId) async {
    final enrollmentSnapshot = await _enrollments
        .where('batchId', isEqualTo: batchId)
        .get();
    final affectedUsers = <String, List<String>>{};

    for (final doc in enrollmentSnapshot.docs) {
      final data = doc.data();
      final userId = (data['userId'] ?? '') as String;
      if (userId.isEmpty) continue;
      affectedUsers.putIfAbsent(userId, () => []).add(batchId);
    }

    final writeBatch = _db.batch();

    for (final doc in enrollmentSnapshot.docs) {
      writeBatch.delete(doc.reference);
    }

    for (final entry in affectedUsers.entries) {
      writeBatch.update(_users.doc(entry.key), {
        'activeBatchIds': FieldValue.arrayRemove(entry.value),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    writeBatch.delete(_batches.doc(batchId));
    await writeBatch.commit();
  }

  Future<void> addResource({
    required String batchId,
    required String title,
    required String url,
  }) {
    final resource = BatchResource(
      id: _batches.doc().id,
      title: title.trim(),
      url: url.trim(),
    );

    return _batches.doc(batchId).update({
      'resources': FieldValue.arrayUnion([resource.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeResource({
    required String batchId,
    required BatchResource resource,
  }) {
    return _batches.doc(batchId).update({
      'resources': FieldValue.arrayRemove([resource.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _buildSchedule(
    List<String> days,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) {
    final start = _formatTimeOfDay(startTime);
    final end = _formatTimeOfDay(endTime);
    return '${days.join(', ')} • $start - $end';
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  DateTime _nextOccurrence({
    required List<String> days,
    required TimeOfDay time,
  }) {
    final now = DateTime.now();
    final validWeekdays = days.map(_weekdayFromLabel).whereType<int>().toList()
      ..sort();

    if (validWeekdays.isEmpty) {
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    }

    DateTime? best;

    for (final weekday in validWeekdays) {
      var diff = weekday - now.weekday;
      if (diff < 0) diff += 7;

      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: diff));
      final candidate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      if (best == null || candidate.isBefore(best)) {
        best = candidate;
      }
    }

    return best ??
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  int? _weekdayFromLabel(String day) {
    switch (day) {
      case 'Mon':
        return DateTime.monday;
      case 'Tue':
        return DateTime.tuesday;
      case 'Wed':
        return DateTime.wednesday;
      case 'Thu':
        return DateTime.thursday;
      case 'Fri':
        return DateTime.friday;
      case 'Sat':
        return DateTime.saturday;
      case 'Sun':
        return DateTime.sunday;
      default:
        return null;
    }
  }
}
