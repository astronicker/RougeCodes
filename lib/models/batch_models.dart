import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BatchResource {
  const BatchResource({
    required this.id,
    required this.title,
    required this.url,
  });

  final String id;
  final String title;
  final String url;

  factory BatchResource.fromMap(Map<String, dynamic> map) {
    return BatchResource(
      id: (map['id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      url: (map['url'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'url': url};
  }
}

class BatchItem {
  const BatchItem({
    required this.id,
    required this.name,
    required this.days,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.startAt,
    required this.endAt,
    required this.schedule,
    required this.enrollmentCount,
    required this.resources,
  });

  final String id;
  final String name;
  final List<String> days;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final DateTime startAt;
  final DateTime endAt;
  final String schedule;
  final int enrollmentCount;
  final List<BatchResource> resources;

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  factory BatchItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    return BatchItem(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      days: (data['days'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      startHour: (data['startHour'] ?? 0) as int,
      startMinute: (data['startMinute'] ?? 0) as int,
      endHour: (data['endHour'] ?? 0) as int,
      endMinute: (data['endMinute'] ?? 0) as int,
      startAt: (data['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt:
          (data['endAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 1)),
      schedule: (data['schedule'] ?? '') as String,
      enrollmentCount: (data['enrollmentCount'] ?? 0) as int,
      resources: (data['resources'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => BatchResource.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class BatchEnrollment {
  const BatchEnrollment({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  final String id;
  final String batchId;
  final String batchName;
  final String userId;
  final String userName;
  final String userEmail;

  factory BatchEnrollment.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return BatchEnrollment(
      id: doc.id,
      batchId: (data['batchId'] ?? '') as String,
      batchName: (data['batchName'] ?? '') as String,
      userId: (data['userId'] ?? '') as String,
      userName: (data['userName'] ?? '') as String,
      userEmail: (data['userEmail'] ?? '') as String,
    );
  }
}
