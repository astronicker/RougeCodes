import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/app_user.dart';
import '../core/models/batch_models.dart';
import '../core/providers/session_provider.dart';
import '../students/provider/student_provider.dart';
import 'provider/batch_provider.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<SessionProvider, BatchProvider, StudentProvider>(
      builder: (context, session, batchProvider, studentProvider, _) {
        if (session.isLoading ||
            batchProvider.isLoading ||
            studentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = session.profile;
        if (profile == null) {
          return const Center(child: Text('No profile found.'));
        }

        if (profile.isAdmin) {
          return _AdminHome(
            batches: batchProvider.batches,
            totalEnrollments: batchProvider.totalEnrollments,
          );
        }

        final enrolledBatches = batchProvider.batches
            .where((batch) => profile.activeBatchIds.contains(batch.id))
            .toList();

        return _StudentHome(profile: profile, batches: enrolledBatches);
      },
    );
  }
}

class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.batches, required this.totalEnrollments});

  final List<BatchItem> batches;
  final int totalEnrollments;

  String _batchStatus(DateTime startAt, DateTime endAt) {
    final now = DateTime.now();
    if (now.isBefore(startAt)) return 'Upcoming';
    if (now.isAfter(endAt)) return 'Completed';
    return 'Live';
  }

  Future<void> _showCreateBatchSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return ChangeNotifierProvider(
          create: (_) => _BatchComposer(),
          child: const _CreateBatchSheet(),
        );
      },
    );
  }

  Future<void> _showBatchDetailsSheet(BuildContext context, BatchItem batch) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _BatchDetailsSheet(batch: batch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBatchSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New batch'),
      ),
      body: RefreshIndicator(
        onRefresh: context.read<BatchProvider>().refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batch Control',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage batches, enrollments, and learning resources.',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fast admin actions with cleaner enrollment management.',
                    style: TextStyle(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _StatGrid(
              children: [
                _StatCard(
                  label: 'Batches',
                  value: '${batches.length}',
                  icon: Icons.grid_view_rounded,
                ),
                _StatCard(
                  label: 'Enrollments',
                  value: '$totalEnrollments',
                  icon: Icons.link_rounded,
                ),
                _StatCard(
                  label: 'Resources',
                  value:
                      '${batches.fold<int>(0, (resourceTotal, batch) => resourceTotal + batch.resources.length)}',
                  icon: Icons.library_books_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'All batches',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (batches.isEmpty)
              _EmptyState(
                icon: Icons.groups_2_rounded,
                title: 'No batches yet',
                subtitle:
                    'Create the first batch to start assigning students and publishing content.',
              )
            else
              ...batches.map((batch) {
                final status = _batchStatus(batch.startAt, batch.endAt);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _showBatchDetailsSheet(context, batch),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 96,
                            decoration: BoxDecoration(
                              color: _statusColor(cs, status),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        batch.name,
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    _StatusChip(
                                      label: status,
                                      color: _statusColor(cs, status),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  batch.schedule,
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _MiniChip(
                                      icon: Icons.people_alt_rounded,
                                      text: '${batch.enrollmentCount} students',
                                    ),
                                    _MiniChip(
                                      icon: Icons.link_rounded,
                                      text:
                                          '${batch.resources.length} resources',
                                    ),
                                    _MiniChip(
                                      icon: Icons.touch_app_rounded,
                                      text: 'Open to manage',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StudentHome extends StatelessWidget {
  const _StudentHome({required this.profile, required this.batches});

  final AppUser profile;
  final List<BatchItem> batches;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primaryContainer, cs.secondaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Learning Space',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Only your enrolled batches and content are visible here.',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MiniChip(
                    icon: Icons.groups_rounded,
                    text: '${batches.length} active batches',
                  ),
                  _MiniChip(
                    icon: Icons.check_circle_rounded,
                    text: '${profile.attendanceRate}% attendance',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'My batches',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (batches.isEmpty)
          _EmptyState(
            icon: Icons.lock_open_rounded,
            title: 'No batch assigned yet',
            subtitle: 'Your admin has not enrolled you into a batch yet.',
          )
        else
          ...batches.map(
            (batch) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.name,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      batch.schedule,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Resources',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (batch.resources.isEmpty)
                      Text(
                        'No content added yet.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      )
                    else
                      ...batch.resources.map(
                        (resource) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surface.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Icon(
                                    Icons.link_rounded,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        resource.title,
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        resource.url,
                                        style: TextStyle(color: cs.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CreateBatchSheet extends StatelessWidget {
  const _CreateBatchSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final composer = context.watch<_BatchComposer>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create batch',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Keep the batch document lean. Student enrollment is stored separately for scale.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: composer.nameController,
                decoration: InputDecoration(
                  labelText: 'Batch name',
                  prefixIcon: const Icon(Icons.groups_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: composer.days.map((day) {
                  final selected = composer.selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: selected,
                    onSelected: (_) => composer.toggleDay(day),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime:
                              composer.startTime ??
                              const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (picked != null) composer.setStartTime(picked);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(composer.startLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime:
                              composer.endTime ??
                              const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (picked != null) composer.setEndTime(picked);
                      },
                      icon: const Icon(Icons.stop_rounded),
                      label: Text(composer.endLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: composer.isSaving
                      ? null
                      : () async {
                          final error = composer.validate();
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                            return;
                          }

                          try {
                            await composer.save(context.read<BatchProvider>());
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Batch created successfully.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not create batch: $e'),
                                ),
                              );
                            }
                          }
                        },
                  child: composer.isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create batch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchDetailsSheet extends StatelessWidget {
  const _BatchDetailsSheet({required this.batch});

  final BatchItem batch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resourceTitleController = TextEditingController();
    final resourceUrlController = TextEditingController();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Consumer2<BatchProvider, StudentProvider>(
            builder: (context, batchProvider, studentProvider, _) {
              final liveBatch = batchProvider.byId(batch.id) ?? batch;
              final enrolledIds = <String>{};

              Future<bool> confirmAction({
                required String title,
                required String message,
                required String confirmLabel,
              }) async {
                final value = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(title),
                    content: Text(message),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(confirmLabel),
                      ),
                    ],
                  ),
                );
                return value ?? false;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          liveBatch.name,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final confirmed = await confirmAction(
                            title: 'Delete batch?',
                            message:
                                'This will remove the batch and all enrollment links connected to it.',
                            confirmLabel: 'Delete',
                          );
                          if (!confirmed) {
                            return;
                          }
                          await batchProvider.deleteBatch(liveBatch.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Batch deleted successfully.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  Text(
                    liveBatch.schedule,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MiniChip(
                        icon: Icons.people_alt_rounded,
                        text: '${liveBatch.enrollmentCount} enrolled',
                      ),
                      _MiniChip(
                        icon: Icons.library_books_rounded,
                        text: '${liveBatch.resources.length} resources',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Batch content',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: resourceTitleController,
                    decoration: InputDecoration(
                      labelText: 'Resource title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: resourceUrlController,
                    decoration: InputDecoration(
                      labelText: 'PDF or link URL',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final title = resourceTitleController.text.trim();
                        final url = resourceUrlController.text.trim();
                        if (title.isEmpty || url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Enter both resource title and URL.',
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          await batchProvider.addResource(
                            batchId: liveBatch.id,
                            title: title,
                            url: url,
                          );
                          resourceTitleController.clear();
                          resourceUrlController.clear();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Resource added successfully.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not add resource: $e'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add_link_rounded),
                      label: const Text('Add resource'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (liveBatch.resources.isEmpty)
                    Text(
                      'No resources added yet.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    )
                  else
                    ...liveBatch.resources.map(
                      (resource) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          tileColor: cs.surfaceContainerHighest.withValues(
                            alpha: 0.55,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(
                              Icons.link_rounded,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          title: Text(resource.title),
                          subtitle: Text(resource.url),
                          trailing: IconButton(
                            onPressed: () async {
                              final confirmed = await confirmAction(
                                title: 'Remove resource?',
                                message:
                                    'This resource link will be removed from the batch.',
                                confirmLabel: 'Remove',
                              );
                              if (!confirmed) {
                                return;
                              }
                              await batchProvider.removeResource(
                                batchId: liveBatch.id,
                                resource: resource,
                              );
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  Text(
                    'Enrolled students',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<BatchEnrollment>>(
                    stream: studentProvider.watchBatchEnrollments(liveBatch.id),
                    builder: (context, snapshot) {
                      final enrollments =
                          snapshot.data ?? const <BatchEnrollment>[];
                      for (final enrollment in enrollments) {
                        enrolledIds.add(enrollment.userId);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (enrollments.isEmpty)
                            Text(
                              'No students enrolled yet.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            )
                          else
                            ...enrollments.map(
                              (enrollment) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  tileColor: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: cs.primaryContainer,
                                    child: Text(
                                      _initials(enrollment.userName),
                                      style: TextStyle(
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  title: Text(enrollment.userName),
                                  subtitle: Text(enrollment.userEmail),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      final student = studentProvider.byId(
                                        enrollment.userId,
                                      );
                                      if (student != null) {
                                        final confirmed = await confirmAction(
                                          title: 'Remove student from batch?',
                                          message:
                                              '${student.name} will lose access to this batch content.',
                                          confirmLabel: 'Remove',
                                        );
                                        if (!confirmed) {
                                          return;
                                        }
                                        studentProvider.removeFromBatch(
                                          student: student,
                                          batch: liveBatch,
                                        );
                                      }
                                    },
                                    child: const Text('Remove'),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                          Text(
                            'Available students',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...studentProvider.students.map(
                            (student) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                tileColor: cs.surface.withValues(alpha: 0.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: cs.secondaryContainer,
                                  child: Text(
                                    _initials(student.name),
                                    style: TextStyle(
                                      color: cs.onSecondaryContainer,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                title: Text(student.name),
                                subtitle: Text(
                                  student.activeBatchIds.isEmpty
                                      ? student.email
                                      : '${student.email}\n${student.activeBatchIds.length} enrolled batches',
                                ),
                                isThreeLine: student.activeBatchIds.isNotEmpty,
                                trailing: enrolledIds.contains(student.uid)
                                    ? const _StatusChip(label: 'Enrolled')
                                    : FilledButton.tonal(
                                        onPressed: () =>
                                            studentProvider.enrollInBatch(
                                              student: student,
                                              batch: liveBatch,
                                            ),
                                        child: const Text('Add'),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BatchComposer extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final List<String> days = const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final Set<String> selectedDays = <String>{};
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isSaving = false;

  String get startLabel =>
      startTime == null ? 'Start time' : _formatTime(startTime!);
  String get endLabel => endTime == null ? 'End time' : _formatTime(endTime!);

  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    notifyListeners();
  }

  void setStartTime(TimeOfDay value) {
    startTime = value;
    notifyListeners();
  }

  void setEndTime(TimeOfDay value) {
    endTime = value;
    notifyListeners();
  }

  String? validate() {
    if (nameController.text.trim().isEmpty) {
      return 'Enter a batch name.';
    }
    if (selectedDays.isEmpty) {
      return 'Select at least one day.';
    }
    if (startTime == null || endTime == null) {
      return 'Choose both start and end times.';
    }
    if (_toMinutes(endTime!) <= _toMinutes(startTime!)) {
      return 'End time must be after start time.';
    }
    return null;
  }

  Future<void> save(BatchProvider provider) async {
    isSaving = true;
    notifyListeners();
    try {
      await provider.createBatch(
        name: nameController.text.trim(),
        days: selectedDays.toList(),
        startTime: startTime!,
        endTime: endTime!,
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  int _toMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

  String _formatTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8.0,
            children: [
              Icon(icon, color: cs.primary),
              Text(
                value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      children: children,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: resolvedColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: cs.primary),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ColorScheme cs, String status) {
  switch (status) {
    case 'Live':
      return cs.primary;
    case 'Upcoming':
      return cs.tertiary;
    default:
      return cs.outline;
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(' ')
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'S';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}
