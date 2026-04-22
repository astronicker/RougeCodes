import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, user }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.activeBatchIds,
    required this.attendancePresentCount,
    required this.attendanceAbsentCount,
    required this.attendanceRate,
    required this.isArchived,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final List<String> activeBatchIds;
  final int attendancePresentCount;
  final int attendanceAbsentCount;
  final int attendanceRate;
  final bool isArchived;

  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;
  int get enrolledBatchCount => activeBatchIds.length;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final roleValue = (data['role'] ?? 'user').toString();

    return AppUser(
      uid: doc.id,
      name: (data['name'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      role: roleValue == 'admin' ? UserRole.admin : UserRole.user,
      activeBatchIds: (data['activeBatchIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      attendancePresentCount: (data['attendancePresentCount'] ?? 0) as int,
      attendanceAbsentCount: (data['attendanceAbsentCount'] ?? 0) as int,
      attendanceRate: (data['attendanceRate'] ?? 0) as int,
      isArchived: (data['isArchived'] ?? false) as bool,
    );
  }
}
