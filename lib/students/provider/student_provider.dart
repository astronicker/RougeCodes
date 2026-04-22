import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/models/batch_models.dart';
import '../../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  StudentProvider() {
    _subscription = _service.watchStudents().listen((items) {
      _students = items;
      _isLoading = false;
      _recalculate();
      notifyListeners();
    });
  }

  final StudentService _service = StudentService.instance;
  StreamSubscription<List<AppUser>>? _subscription;

  List<AppUser> _students = [];
  bool _isLoading = true;
  bool _isWorking = false;
  final Set<String> _busyAttendanceKeys = <String>{};

  List<AppUser> get students => _students;
  bool get isLoading => _isLoading;
  bool get isWorking => _isWorking;

  String attendanceBusyKey(String studentId, String batchId) =>
      '$studentId::$batchId';

  bool isAttendanceBusy(String studentId, String batchId) {
    return _busyAttendanceKeys.contains(attendanceBusyKey(studentId, batchId));
  }

  int totalStudents = 0;
  int totalPresentMarks = 0;
  int totalAbsentMarks = 0;
  int attendanceRate = 0;

  AppUser? byId(String id) {
    try {
      return _students.firstWhere((student) => student.uid == id);
    } catch (_) {
      return null;
    }
  }

  void _recalculate() {
    totalStudents = _students.length;
    totalPresentMarks = 0;
    totalAbsentMarks = 0;

    for (final student in _students) {
      totalPresentMarks += student.attendancePresentCount;
      totalAbsentMarks += student.attendanceAbsentCount;
    }

    final totalMarks = totalPresentMarks + totalAbsentMarks;
    attendanceRate = totalMarks == 0
        ? 0
        : ((totalPresentMarks / totalMarks) * 100).round();
  }

  Future<void> _runBusy(Future<void> Function() task) async {
    _isWorking = true;
    notifyListeners();
    try {
      await task();
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  Future<void> createStudent({
    required String name,
    required String email,
    required String password,
    required List<BatchItem> initialBatches,
  }) {
    return _runBusy(() {
      return _service.createStudent(
        name: name,
        email: email,
        password: password,
        initialBatches: initialBatches,
      );
    });
  }

  Future<void> updateStudent({
    required String studentId,
    required String name,
  }) {
    return _runBusy(() {
      return _service.updateStudent(studentId: studentId, name: name);
    });
  }

  Future<void> archiveStudent(AppUser student) {
    return _runBusy(() => _service.archiveStudent(student));
  }

  Future<void> enrollInBatch({
    required AppUser student,
    required BatchItem batch,
  }) {
    return _runBusy(() {
      return _service.enrollStudentInBatch(student: student, batch: batch);
    });
  }

  Future<void> removeFromBatch({
    required AppUser student,
    required BatchItem batch,
  }) {
    return _runBusy(() {
      return _service.removeStudentFromBatch(student: student, batch: batch);
    });
  }

  Future<void> markAttendance({
    required String studentId,
    required String batchId,
    required String batchName,
    required String status,
  }) async {
    final key = attendanceBusyKey(studentId, batchId);
    _busyAttendanceKeys.add(key);
    notifyListeners();
    try {
      await _service.markAttendance(
        studentId: studentId,
        batchId: batchId,
        batchName: batchName,
        status: status,
      );
    } finally {
      _busyAttendanceKeys.remove(key);
      notifyListeners();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> attendanceHistory(
    String studentId,
  ) {
    return _service.getAttendanceHistory(studentId);
  }

  Stream<AppUser?> watchStudent(String studentId) {
    return _service.watchStudent(studentId);
  }

  Stream<List<BatchEnrollment>> watchStudentEnrollments(String studentId) {
    return _service.watchEnrollmentsForStudent(studentId);
  }

  Stream<List<BatchEnrollment>> watchBatchEnrollments(String batchId) {
    return _service.watchEnrollmentsForBatch(batchId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
