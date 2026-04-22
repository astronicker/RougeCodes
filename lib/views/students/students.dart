import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/batch_models.dart';
import '../../providers/batch_provider.dart';
import '../../providers/student_provider.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  Future<void> _showAddStudentSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ChangeNotifierProvider(
        create: (_) => _StudentComposer(),
        child: const _CreateStudentSheet(),
      ),
    );
  }

  Future<void> _showStudentDetailsSheet(BuildContext context, AppUser student) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _StudentDetailsSheet(studentId: student.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudentProvider, BatchProvider>(
      builder: (context, studentProvider, batchProvider, _) {
        if (studentProvider.isLoading || batchProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final cs = Theme.of(context).colorScheme;
        final students = studentProvider.students;
        final batchesById = {
          for (final batch in batchProvider.batches) batch.id: batch,
        };

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddStudentSheet(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('New student'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                'All stats',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _StatGrid(
                children: [
                  _StatCard(
                    label: 'Students',
                    value: '${studentProvider.totalStudents}',
                    icon: Icons.people_alt_rounded,
                  ),
                  _StatCard(
                    label: 'Present',
                    value: '${studentProvider.totalPresentMarks}',
                    icon: Icons.check_circle_rounded,
                  ),
                  _StatCard(
                    label: 'Absent',
                    value: '${studentProvider.totalAbsentMarks}',
                    icon: Icons.cancel_rounded,
                  ),
                  _StatCard(
                    label: 'Rate',
                    value: '${studentProvider.attendanceRate}%',
                    icon: Icons.insights_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'All students',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (students.isEmpty)
                _EmptyState(
                  icon: Icons.school_outlined,
                  title: 'No students yet',
                  subtitle:
                      'Create the first student to enable enrollment and attendance tracking.',
                )
              else
                ...students.map((student) {
                  final enrolledNames = student.activeBatchIds
                      .map((id) => batchesById[id]?.name)
                      .whereType<String>()
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.55,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            18,
                            0,
                            18,
                            18,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              _initials(student.name),
                              style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              student.email,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StatusChip(label: '${student.attendanceRate}%'),
                            ],
                          ),
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _MiniChip(
                                  icon: Icons.groups_rounded,
                                  text: enrolledNames.isEmpty
                                      ? 'No batches assigned'
                                      : enrolledNames.join(', '),
                                ),
                                _MiniChip(
                                  icon: Icons.check_circle_rounded,
                                  text: 'P ${student.attendancePresentCount}',
                                ),
                                _MiniChip(
                                  icon: Icons.cancel_rounded,
                                  text: 'A ${student.attendanceAbsentCount}',
                                ),
                              ],
                            ),
                            if (student.activeBatchIds.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Quick attendance',
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...student.activeBatchIds
                                  .map((batchId) => batchesById[batchId])
                                  .whereType<BatchItem>()
                                  .map(
                                    (batch) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: cs.surface.withValues(
                                            alpha: 0.9,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              batch.name,
                                              style: TextStyle(
                                                color: cs.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Builder(
                                              builder: (context) {
                                                final isBusy = studentProvider
                                                    .isAttendanceBusy(
                                                      student.uid,
                                                      batch.id,
                                                    );
                                                return Row(
                                                  children: [
                                                    Expanded(
                                                      child: FilledButton.tonalIcon(
                                                        onPressed: isBusy
                                                            ? null
                                                            : () => studentProvider
                                                                  .markAttendance(
                                                                    studentId:
                                                                        student
                                                                            .uid,
                                                                    batchId:
                                                                        batch
                                                                            .id,
                                                                    batchName:
                                                                        batch
                                                                            .name,
                                                                    status:
                                                                        'present',
                                                                  ),
                                                        icon: const Icon(
                                                                Icons
                                                                    .check_circle_rounded,
                                                              ),
                                                        label: const Text(
                                                          'Present',
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: FilledButton.tonalIcon(
                                                        onPressed: isBusy
                                                            ? null
                                                            : () => studentProvider
                                                                  .markAttendance(
                                                                    studentId:
                                                                        student
                                                                            .uid,
                                                                    batchId:
                                                                        batch
                                                                            .id,
                                                                    batchName:
                                                                        batch
                                                                            .name,
                                                                    status:
                                                                        'absent',
                                                                  ),
                                                        icon: const Icon(
                                                          Icons.cancel_rounded,
                                                        ),
                                                        label: const Text(
                                                          'Absent',
                                                        ),
                                                        style: ButtonStyle(
                                                          backgroundColor:
                                                              WidgetStatePropertyAll(
                                                                cs.errorContainer,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _showStudentDetailsSheet(
                                      context,
                                      student,
                                    ),
                                    child: const Text('Open details'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _CreateStudentSheet extends StatelessWidget {
  const _CreateStudentSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final composer = context.watch<_StudentComposer>();
    final batches = context.watch<BatchProvider>().batches;

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
                'Create student',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can assign one or multiple batches during account creation.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: composer.nameController,
                decoration: InputDecoration(
                  labelText: 'Student name',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: composer.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Student email',
                  prefixIcon: const Icon(Icons.email_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: composer.passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Assign batches',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (batches.isEmpty)
                Text(
                  'Create at least one batch first.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                )
              else
                ...batches.map(
                  (batch) => CheckboxListTile(
                    value: composer.selectedBatchIds.contains(batch.id),
                    onChanged: (_) => composer.toggleBatch(batch.id),
                    title: Text(batch.name),
                    subtitle: Text(batch.schedule),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: composer.isSaving || batches.isEmpty
                      ? null
                      : () async {
                          final error = composer.validate();
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                            return;
                          }

                          final initialBatches = batches
                              .where(
                                (batch) => composer.selectedBatchIds.contains(
                                  batch.id,
                                ),
                              )
                              .toList();

                          try {
                            await composer.save(
                              context.read<StudentProvider>(),
                              initialBatches,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Student created successfully.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not create student: $e'),
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
                      : const Text('Create student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentDetailsSheet extends StatelessWidget {
  const _StudentDetailsSheet({required this.studentId});

  final String studentId;

  String _prettyDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _prettyTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.read<StudentProvider>();
    final batchProvider = context.read<BatchProvider>();
    final nameController = TextEditingController();

    return StreamBuilder<AppUser?>(
      stream: studentProvider.watchStudent(studentId),
      builder: (context, snapshot) {
        final student = snapshot.data ?? studentProvider.byId(studentId);
        if (student == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        nameController.text = student.name;
        final cs = Theme.of(context).colorScheme;

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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          _initials(student.name),
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              student.email,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final confirmed = await confirmAction(
                            title: 'Delete student?',
                            message:
                                'The student record will be archived and removed from all batch enrollments.',
                            confirmLabel: 'Delete',
                          );
                          if (!confirmed) {
                            return;
                          }
                          await studentProvider.archiveStudent(student);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Student archived successfully.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MiniChip(
                        icon: Icons.groups_rounded,
                        text: '${student.enrolledBatchCount} batches',
                      ),
                      _MiniChip(
                        icon: Icons.check_circle_rounded,
                        text: '${student.attendancePresentCount} present',
                      ),
                      _MiniChip(
                        icon: Icons.cancel_rounded,
                        text: '${student.attendanceAbsentCount} absent',
                      ),
                      _MiniChip(
                        icon: Icons.insights_rounded,
                        text: '${student.attendanceRate}% rate',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Update profile',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Student name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Student name cannot be empty.'),
                            ),
                          );
                          return;
                        }
                        await studentProvider.updateStudent(
                          studentId: student.uid,
                          name: nameController.text.trim(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Student name updated.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Save name'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Batch enrollments',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<BatchEnrollment>>(
                    stream: studentProvider.watchStudentEnrollments(
                      student.uid,
                    ),
                    builder: (context, enrollmentsSnapshot) {
                      final enrollments =
                          enrollmentsSnapshot.data ?? const <BatchEnrollment>[];
                      final enrolledIds = enrollments
                          .map((item) => item.batchId)
                          .toSet();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (enrollments.isEmpty)
                            Text(
                              'No batch assigned yet.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            )
                          else
                            ...enrollments.map((enrollment) {
                              final batch = batchProvider.byId(
                                enrollment.batchId,
                              );
                              if (batch == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  tileColor: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  title: Text(batch.name),
                                  subtitle: Text(batch.schedule),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      final confirmed = await confirmAction(
                                        title: 'Remove batch enrollment?',
                                        message:
                                            '${student.name} will lose access to ${batch.name}.',
                                        confirmLabel: 'Remove',
                                      );
                                      if (!confirmed) {
                                        return;
                                      }
                                      studentProvider.removeFromBatch(
                                        student: student,
                                        batch: batch,
                                      );
                                    },
                                    child: const Text('Remove'),
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 12),
                          Text(
                            'Add to more batches',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...batchProvider.batches
                              .where((batch) => !enrolledIds.contains(batch.id))
                              .map(
                                (batch) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    tileColor: cs.surface.withValues(
                                      alpha: 0.8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    title: Text(batch.name),
                                    subtitle: Text(batch.schedule),
                                    trailing: FilledButton.tonal(
                                      onPressed: () =>
                                          studentProvider.enrollInBatch(
                                            student: student,
                                            batch: batch,
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
                  const SizedBox(height: 22),
                  Text(
                    'Attendance actions',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<BatchEnrollment>>(
                    stream: studentProvider.watchStudentEnrollments(
                      student.uid,
                    ),
                    builder: (context, snapshot) {
                      final enrollments =
                          snapshot.data ?? const <BatchEnrollment>[];
                      if (enrollments.isEmpty) {
                        return Text(
                          'Assign a batch before marking attendance.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        );
                      }

                      return Column(
                        children: enrollments.map((enrollment) {
                          final isBusy = studentProvider.isAttendanceBusy(
                            student.uid,
                            enrollment.batchId,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(
                                  alpha: 0.55,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    enrollment.batchName,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.tonalIcon(
                                          onPressed: isBusy
                                              ? null
                                              : () => studentProvider
                                                    .markAttendance(
                                                      studentId: student.uid,
                                                      batchId:
                                                          enrollment.batchId,
                                                      batchName:
                                                          enrollment.batchName,
                                                      status: 'present',
                                                    ),
                                          icon: isBusy
                                              ? const SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.check_circle_rounded,
                                                ),
                                          label: const Text('Present'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.tonalIcon(
                                          onPressed: isBusy
                                              ? null
                                              : () => studentProvider
                                                    .markAttendance(
                                                      studentId: student.uid,
                                                      batchId:
                                                          enrollment.batchId,
                                                      batchName:
                                                          enrollment.batchName,
                                                      status: 'absent',
                                                    ),
                                          icon: const Icon(
                                            Icons.cancel_rounded,
                                          ),
                                          label: const Text('Absent'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Attendance history',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: studentProvider.attendanceHistory(student.uid),
                    builder: (context, historySnapshot) {
                      final docs = historySnapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Text(
                          'No attendance recorded yet.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          final date = (data['date'] as Timestamp?)?.toDate();
                          final status = (data['status'] ?? '') as String;
                          final batchName = (data['batchName'] ?? '') as String;
                          final isPresent = status == 'present';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              tileColor: cs.surfaceContainerHighest.withValues(
                                alpha: 0.55,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    (isPresent ? cs.primary : cs.error)
                                        .withValues(alpha: 0.15),
                                child: Icon(
                                  isPresent
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  color: isPresent ? cs.primary : cs.error,
                                ),
                              ),
                              title: Text(isPresent ? 'Present' : 'Absent'),
                              subtitle: Text(
                                '$batchName${date == null ? '' : ' • ${_prettyDate(date)} ${_prettyTime(date)}'}',
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StudentComposer extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Set<String> selectedBatchIds = <String>{};
  bool isSaving = false;

  void toggleBatch(String batchId) {
    if (selectedBatchIds.contains(batchId)) {
      selectedBatchIds.remove(batchId);
    } else {
      selectedBatchIds.add(batchId);
    }
    notifyListeners();
  }

  String? validate() {
    if (nameController.text.trim().isEmpty) {
      return 'Enter the student name.';
    }
    if (!emailController.text.trim().contains('@')) {
      return 'Enter a valid email.';
    }
    if (passwordController.text.trim().length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (selectedBatchIds.isEmpty) {
      return 'Select at least one batch.';
    }
    return null;
  }

  Future<void> save(
    StudentProvider provider,
    List<BatchItem> initialBatches,
  ) async {
    isSaving = true;
    notifyListeners();
    try {
      await provider.createStudent(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        initialBatches: initialBatches,
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
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
              Icon(icon, color: cs.tertiary),
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
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
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
