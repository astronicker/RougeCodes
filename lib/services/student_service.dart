import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/firebase_options.dart';
import '../models/app_user.dart';
import '../models/batch_models.dart';

class StudentService {
  StudentService._();

  static final StudentService instance = StudentService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _creatorAppName = 'student_creator_app';

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _batches =>
      _db.collection('batches');
  CollectionReference<Map<String, dynamic>> get _enrollments =>
      _db.collection('batch_enrollments');

  Future<FirebaseApp> _ensureCreatorApp() async {
    try {
      return Firebase.app(_creatorAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _creatorAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<FirebaseAuth> _creatorAuth() async {
    final app = await _ensureCreatorApp();
    return FirebaseAuth.instanceFor(app: app);
  }

  Stream<List<AppUser>> watchStudents() {
    return _users
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppUser.fromDoc)
              .where((user) => user.isUser && !user.isArchived)
              .toList(),
        );
  }

  Stream<AppUser?> watchStudent(String studentId) {
    return _users.doc(studentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    });
  }

  Stream<List<BatchEnrollment>> watchEnrollmentsForStudent(String studentId) {
    return _enrollments
        .where('userId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(BatchEnrollment.fromDoc).toList());
  }

  Stream<List<BatchEnrollment>> watchEnrollmentsForBatch(String batchId) {
    return _enrollments
        .where('batchId', isEqualTo: batchId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(BatchEnrollment.fromDoc).toList());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAttendanceHistory(
    String studentId,
  ) {
    return _users
        .doc(studentId)
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> createStudent({
    required String name,
    required String email,
    required String password,
    required List<BatchItem> initialBatches,
  }) async {
    final creatorAuth = await _creatorAuth();

    final credential = await creatorAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = credential.user!.uid;

    try {
      await _users.doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': 'user',
        'activeBatchIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'attendancePresentCount': 0,
        'attendanceAbsentCount': 0,
        'attendanceRate': 0,
        'isArchived': false,
        'lastAttendanceDate': null,
      });

      final student = AppUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: UserRole.user,
        activeBatchIds: const [],
        attendancePresentCount: 0,
        attendanceAbsentCount: 0,
        attendanceRate: 0,
        isArchived: false,
      );

      for (final batch in initialBatches) {
        await enrollStudentInBatch(student: student, batch: batch);
      }
    } catch (e) {
      await credential.user?.delete();
      rethrow;
    } finally {
      await creatorAuth.signOut();
    }
  }

  Future<void> updateStudent({
    required String studentId,
    required String name,
  }) async {
    final enrollmentSnapshot = await _enrollments
        .where('userId', isEqualTo: studentId)
        .get();
    final writeBatch = _db.batch();

    writeBatch.update(_users.doc(studentId), {
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final doc in enrollmentSnapshot.docs) {
      writeBatch.update(doc.reference, {
        'userName': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await writeBatch.commit();
  }

  Future<void> archiveStudent(AppUser student) async {
    final enrollmentSnapshot = await _enrollments
        .where('userId', isEqualTo: student.uid)
        .get();
    final writeBatch = _db.batch();

    // The Auth account is intentionally left intact here. Full credential deletion
    // should be handled by a privileged backend or Firebase Admin environment.
    for (final doc in enrollmentSnapshot.docs) {
      final data = doc.data();
      final batchId = (data['batchId'] ?? '') as String;
      if (batchId.isNotEmpty) {
        writeBatch.update(_batches.doc(batchId), {
          'enrollmentCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      writeBatch.delete(doc.reference);
    }

    writeBatch.update(_users.doc(student.uid), {
      'isArchived': true,
      'activeBatchIds': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await writeBatch.commit();
  }

  Future<void> enrollStudentInBatch({
    required AppUser student,
    required BatchItem batch,
  }) async {
    final enrollmentId = '${batch.id}_${student.uid}';
    final enrollmentRef = _enrollments.doc(enrollmentId);
    final userRef = _users.doc(student.uid);
    final batchRef = _batches.doc(batch.id);

    await _db.runTransaction((tx) async {
      final enrollmentSnap = await tx.get(enrollmentRef);
      if (enrollmentSnap.exists) return;

      final userSnap = await tx.get(userRef);
      final batchSnap = await tx.get(batchRef);

      if (!userSnap.exists || !batchSnap.exists) {
        throw Exception('Could not find the selected student or batch.');
      }

      final data = userSnap.data() ?? <String, dynamic>{};
      final activeBatchIds =
          (data['activeBatchIds'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList();

      if (!activeBatchIds.contains(batch.id)) {
        activeBatchIds.add(batch.id);
      }

      tx.set(enrollmentRef, {
        'batchId': batch.id,
        'batchName': batch.name,
        'userId': student.uid,
        'userName': student.name,
        'userEmail': student.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {
        'activeBatchIds': activeBatchIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(batchRef, {
        'enrollmentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeStudentFromBatch({
    required AppUser student,
    required BatchItem batch,
  }) async {
    final enrollmentRef = _enrollments.doc('${batch.id}_${student.uid}');
    final userRef = _users.doc(student.uid);
    final batchRef = _batches.doc(batch.id);

    await _db.runTransaction((tx) async {
      final enrollmentSnap = await tx.get(enrollmentRef);
      if (!enrollmentSnap.exists) return;

      final userSnap = await tx.get(userRef);
      final batchSnap = await tx.get(batchRef);

      if (!userSnap.exists || !batchSnap.exists) {
        throw Exception('Could not find the selected student or batch.');
      }

      final userData = userSnap.data() ?? <String, dynamic>{};
      final activeBatchIds =
          (userData['activeBatchIds'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .where((item) => item != batch.id)
              .toList();

      final batchData = batchSnap.data() ?? <String, dynamic>{};
      final currentCount = (batchData['enrollmentCount'] ?? 0) as int;

      tx.delete(enrollmentRef);
      tx.update(userRef, {
        'activeBatchIds': activeBatchIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(batchRef, {
        'enrollmentCount': currentCount > 0 ? currentCount - 1 : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markAttendance({
    required String studentId,
    required String batchId,
    required String batchName,
    required String status,
  }) async {
    final now = DateTime.now();
    final todayId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-$batchId';

    final userRef = _users.doc(studentId);
    final attendanceRef = userRef.collection('attendance').doc(todayId);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw Exception('Student not found');
      }

      final attendanceSnap = await tx.get(attendanceRef);

      final userData = userSnap.data() ?? {};
      var presentCount = (userData['attendancePresentCount'] ?? 0) as int;
      var absentCount = (userData['attendanceAbsentCount'] ?? 0) as int;

      final previousStatus = attendanceSnap.data()?['status'] as String?;

      if (previousStatus == null) {
        if (status == 'present') {
          presentCount += 1;
        } else {
          absentCount += 1;
        }
      } else if (previousStatus != status) {
        if (previousStatus == 'present') {
          presentCount -= 1;
        } else {
          absentCount -= 1;
        }

        if (status == 'present') {
          presentCount += 1;
        } else {
          absentCount += 1;
        }
      }

      final total = presentCount + absentCount;
      final rate = total == 0 ? 0 : ((presentCount / total) * 100).round();

      tx.set(attendanceRef, {
        'date': Timestamp.fromDate(now),
        'status': status,
        'batchId': batchId,
        'batchName': batchName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.update(userRef, {
        'attendancePresentCount': presentCount,
        'attendanceAbsentCount': absentCount,
        'attendanceRate': rate,
        'lastAttendanceDate': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
