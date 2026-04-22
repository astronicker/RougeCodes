import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/providers/session_provider.dart';
import '../home/provider/batch_provider.dart';
import '../students/provider/student_provider.dart';

class UserDashboardPage extends StatelessWidget {
  const UserDashboardPage({super.key});

  Future<void> _copyResourceLink(BuildContext context, String rawUrl) async {
    await Clipboard.setData(ClipboardData(text: rawUrl));
  }

  Future<void> _openResource(BuildContext context, String rawUrl) async {
    final normalizedUrl =
        rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
        ? rawUrl
        : 'https://$rawUrl';
    final uri = Uri.tryParse(normalizedUrl);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This resource link is invalid.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this resource.')),
      );
    }
  }

  String _prettyDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String _prettyTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SessionProvider, BatchProvider, StudentProvider>(
      builder: (context, session, batchProvider, studentProvider, _) {
        if (session.isLoading || batchProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = session.profile;
        if (profile == null) {
          return const Center(child: Text('No user profile found.'));
        }

        final enrolledBatches = batchProvider.batches
            .where((batch) => profile.activeBatchIds.contains(batch.id))
            .toList();
        final totalResources = enrolledBatches.fold<int>(
          0,
          (resourceTotal, batch) => resourceTotal + batch.resources.length,
        );
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
                    'My Dashboard',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your batches, resources, and attendance.',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Everything you need is here.',
                    style: TextStyle(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.86),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MiniChip(
                        icon: Icons.groups_rounded,
                        text: '${enrolledBatches.length} batches',
                      ),
                      _MiniChip(
                        icon: Icons.library_books_rounded,
                        text: '$totalResources resources',
                      ),
                      _MiniChip(
                        icon: Icons.insights_rounded,
                        text: '${profile.attendanceRate}% attendance',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _StatGrid(
              children: [
                _StatCard(
                  label: 'Present',
                  value: '${profile.attendancePresentCount}',
                  icon: Icons.check_circle_rounded,
                ),
                _StatCard(
                  label: 'Absent',
                  value: '${profile.attendanceAbsentCount}',
                  icon: Icons.cancel_rounded,
                ),
                _StatCard(
                  label: 'Rate',
                  value: '${profile.attendanceRate}%',
                  icon: Icons.query_stats_rounded,
                ),
                _StatCard(
                  label: 'Resources',
                  value: '$totalResources',
                  icon: Icons.library_books_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Enrolled batches',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (enrolledBatches.isEmpty)
              const _EmptyState(
                title: 'No batches assigned',
                subtitle: 'Your admin has not enrolled you in a batch yet.',
                icon: Icons.lock_outline_rounded,
              )
            else
              ...enrolledBatches.map(
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
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(top: 8),
                            title: Text(
                              'Shared resources (${batch.resources.length})',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              batch.resources.isEmpty
                                  ? 'No shared content yet.'
                                  : 'Tap to expand and access all links.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            children: [
                              if (batch.resources.isEmpty)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'No content added yet.',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              else
                                ...batch.resources.map(
                                  (resource) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: cs.surface.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          onTap: () => _openResource(
                                            context,
                                            resource.url,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor:
                                                      cs.primaryContainer,
                                                  child: Icon(
                                                    Icons.link_rounded,
                                                    color:
                                                        cs.onPrimaryContainer,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        resource.title,
                                                        style: TextStyle(
                                                          color: cs.onSurface,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        resource.url,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: cs.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton.filledTonal(
                                                      tooltip: 'Copy link',
                                                      onPressed: () =>
                                                          _copyResourceLink(
                                                            context,
                                                            resource.url,
                                                          ),
                                                      icon: const Icon(
                                                        Icons
                                                            .content_copy_rounded,
                                                      ),
                                                    ),
                                                    IconButton.filledTonal(
                                                      onPressed: () {},
                                                      color:
                                                          cs.onSurfaceVariant,
                                                      icon: Icon(
                                                        Icons
                                                            .open_in_new_rounded,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'Attendance history',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: studentProvider.attendanceHistory(profile.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _EmptyState(
                    title: 'No attendance records',
                    subtitle:
                        'Attendance marked by admin will appear here automatically.',
                    icon: Icons.event_note_rounded,
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final status = (data['status'] ?? '') as String;
                    final batchName = (data['batchName'] ?? '') as String;
                    final date = (data['date'] as Timestamp?)?.toDate();
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
                          backgroundColor: (isPresent ? cs.primary : cs.error)
                              .withValues(alpha: 0.15),
                          child: Icon(
                            isPresent
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
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
        );
      },
    );
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
              const SizedBox(height: 10),
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
        color: cs.surface.withValues(alpha: 0.88),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

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
