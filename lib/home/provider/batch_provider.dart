import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/batch_models.dart';
import '../../services/batch_service.dart';

class BatchProvider extends ChangeNotifier {
  BatchProvider() {
    _listenBatches();
  }

  final BatchService _service = BatchService.instance;
  StreamSubscription<List<BatchItem>>? _batchSubscription;

  List<BatchItem> _batches = [];
  bool _isLoading = true;

  List<BatchItem> get batches => _batches;
  bool get isLoading => _isLoading;

  int upcoming = 0;
  int live = 0;
  int completed = 0;
  int totalEnrollments = 0;

  BatchItem? byId(String id) {
    try {
      return _batches.firstWhere((batch) => batch.id == id);
    } catch (_) {
      return null;
    }
  }

  void _listenBatches() {
    _batchSubscription?.cancel();
    _batchSubscription = _service.watchBatches().listen(
      (items) {
        _batches = items;
        _isLoading = false;
        _recalculate();
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _recalculate() {
    final now = DateTime.now();
    upcoming = 0;
    live = 0;
    completed = 0;
    totalEnrollments = 0;

    for (final batch in _batches) {
      totalEnrollments += batch.enrollmentCount;
      if (now.isBefore(batch.startAt)) {
        upcoming += 1;
      } else if (now.isAfter(batch.endAt)) {
        completed += 1;
      } else {
        live += 1;
      }
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    _batches = await _service.fetchBatches();
    _isLoading = false;
    _recalculate();
    notifyListeners();
  }

  Future<void> createBatch({
    required String name,
    required List<String> days,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    return _service.createBatch(
      name: name,
      days: days,
      startTime: startTime,
      endTime: endTime,
    );
  }

  Future<void> deleteBatch(String batchId) {
    return _service.deleteBatch(batchId);
  }

  Future<void> addResource({
    required String batchId,
    required String title,
    required String url,
  }) {
    return _service.addResource(batchId: batchId, title: title, url: url);
  }

  Future<void> removeResource({
    required String batchId,
    required BatchResource resource,
  }) {
    return _service.removeResource(batchId: batchId, resource: resource);
  }

  @override
  void dispose() {
    _batchSubscription?.cancel();
    super.dispose();
  }
}
