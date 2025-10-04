import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/services/auth_controller.dart';
import 'package:toll_cam_finder/services/local_segments_service.dart';
import 'package:toll_cam_finder/services/remote_segments_service.dart';
import 'package:toll_cam_finder/services/segments_repository.dart';

import '../../app/app_routes.dart';

class SegmentsPage extends StatefulWidget {
  const SegmentsPage({super.key});

  @override
  State<SegmentsPage> createState() => _SegmentsPageState();
}

enum _SegmentAction { delete }

class _SegmentsPageState extends State<SegmentsPage> {
  final SegmentsRepository _repository = SegmentsRepository();
  final LocalSegmentsService _localSegmentsService = LocalSegmentsService();
  late Future<List<SegmentInfo>> _segmentsFuture;
  bool _segmentsUpdated = false;

  @override
  void initState() {
    super.initState();
    _segmentsFuture = _repository.loadSegments();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_segmentsUpdated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Segments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.folder_special_outlined),
              tooltip: 'Local segments',
              onPressed: _onShowLocalSegmentsPressed,
            ),
          ],
        ),
        body: FutureBuilder<List<SegmentInfo>>(
          future: _segmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorView(
                onRetry: () {
                  setState(() {
                    _segmentsFuture = _repository.loadSegments();
                  });
                },
              );
            }

            final segments = snapshot.data ?? const <SegmentInfo>[];
            if (segments.isEmpty) {
              return const _EmptySegmentsView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: segments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final segment = segments[index];
                return _SegmentCard(
                  segment: segment,
                  onLongPress: () => _onSegmentLongPress(segment),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onCreateSegmentPressed,
          icon: const Icon(Icons.add),
          label: const Text('Create segment'),
        ),
      ),
    );
  }

  Future<void> _onShowLocalSegmentsPressed() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.localSegments);
    if (!mounted || result != true) {
      return;
    }

    _segmentsUpdated = true;
    setState(() {
      _segmentsFuture = _repository.loadSegments();
    });
  }

  Future<void> _onCreateSegmentPressed() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.createSegment);
    if (!mounted || result != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segment saved locally.')),
    );

    _segmentsUpdated = true;
    setState(() {
      _segmentsFuture = _repository.loadSegments();
    });
  }

  Future<void> _onSegmentLongPress(SegmentInfo segment) async {
    final action = await _showSegmentActionsSheet(context, segment);
    if (!mounted || action != _SegmentAction.delete) {
      return;
    }

    await _confirmAndDeleteSegment(segment);
  }

  Future<void> _confirmAndDeleteSegment(SegmentInfo segment) async {
    final confirmed = await _showDeleteConfirmationDialog(context, segment);
    if (!mounted || !confirmed) {
      return;
    }

    final proceed = await _handleRemoteSubmissionCancellation(segment);
    if (!mounted || !proceed) {
      return;
    }

    await _deleteSegment(segment);
  }

  Future<bool> _handleRemoteSubmissionCancellation(SegmentInfo segment) async {
    if (!segment.isMarkedPublic) {
      return true;
    }

    final shouldWithdraw =
        await _showCancelRemoteSubmissionDialog(context, segment);
    if (!mounted) {
      return false;
    }

    if (shouldWithdraw != true) {
      return true;
    }

    final messenger = ScaffoldMessenger.of(context);

    AuthController auth;
    try {
      auth = context.read<AuthController>();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to withdraw the public submission.'),
        ),
      );
      return false;
    }

    if (!auth.isLoggedIn || !auth.isConfigured) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please sign in to withdraw the public submission.'),
        ),
      );
      return false;
    }

    final userId = auth.currentUserId;
    final client = auth.client;
    if (userId == null || userId.isEmpty || client == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to withdraw the public submission.'),
        ),
      );
      return false;
    }

    final remoteService = RemoteSegmentsService(client: client);

    try {
      final deleted = await remoteService.deletePendingSubmission(
        addedByUserId: userId,
        name: segment.name,
        startCoordinates: segment.start,
        endCoordinates: segment.end,
      );

      if (deleted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Segment ${segment.displayId} will no longer be reviewed for public release.',
            ),
          ),
        );
      }

      return true;
    } on RemoteSegmentsServiceException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return false;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel the public review for this segment.'),
        ),
      );
      return false;
    }
  }

  Future<void> _deleteSegment(SegmentInfo segment) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final deleted = await _localSegmentsService.deleteLocalSegment(segment.id);
      if (!mounted) {
        return;
      }

      if (!deleted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to delete the segment.')),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Segment ${segment.displayId} deleted.')),
      );
      _segmentsUpdated = true;
      setState(() {
        _segmentsFuture = _repository.loadSegments();
      });
    } on LocalSegmentsServiceException catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete the segment.')),
      );
    }
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.segment,
    this.onLongPress,
  });

  final SegmentInfo segment;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Segment ${segment.displayId}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  if (segment.isLocalOnly) ...[
                    const SizedBox(width: 8),
                    const _LocalBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(segment.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                        _SegmentLocation(label: 'Start', value: segment.start),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SegmentLocation(label: 'End', value: segment.end),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Local',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _SegmentLocation extends StatelessWidget {
  const _SegmentLocation({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class LocalSegmentsPage extends StatefulWidget {
  const LocalSegmentsPage({super.key});

  @override
  State<LocalSegmentsPage> createState() => _LocalSegmentsPageState();
}

class _LocalSegmentsPageState extends State<LocalSegmentsPage> {
  final SegmentsRepository _repository = SegmentsRepository();
  final LocalSegmentsService _localSegmentsService = LocalSegmentsService();
  late Future<List<SegmentInfo>> _segmentsFuture;
  bool _segmentsUpdated = false;

  @override
  void initState() {
    super.initState();
    _segmentsFuture = _repository.loadSegments(onlyLocal: true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_segmentsUpdated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Local segments')),
        body: FutureBuilder<List<SegmentInfo>>(
          future: _segmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorView(
                onRetry: () {
                  setState(() {
                    _segmentsFuture = _repository.loadSegments(onlyLocal: true);
                  });
                },
              );
            }

            final segments = snapshot.data ?? const <SegmentInfo>[];
            if (segments.isEmpty) {
              return const _EmptyLocalSegmentsView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: segments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final segment = segments[index];
                return _SegmentCard(
                  segment: segment,
                  onLongPress: () => _onSegmentLongPress(segment),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onCreateSegmentPressed,
          icon: const Icon(Icons.add),
          label: const Text('Create segment'),
        ),
      ),
    );
  }

  Future<void> _onCreateSegmentPressed() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.createSegment);
    if (!mounted || result != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segment saved locally.')),
    );

    _segmentsUpdated = true;
    setState(() {
      _segmentsFuture = _repository.loadSegments(onlyLocal: true);
    });
  }

  Future<void> _onSegmentLongPress(SegmentInfo segment) async {
    final action = await _showSegmentActionsSheet(context, segment);
    if (!mounted || action != _SegmentAction.delete) {
      return;
    }

    await _confirmAndDeleteSegment(segment);
  }

  Future<void> _confirmAndDeleteSegment(SegmentInfo segment) async {
    final confirmed = await _showDeleteConfirmationDialog(context, segment);
    if (!mounted || !confirmed) {
      return;
    }

    final proceed = await _handleRemoteSubmissionCancellation(segment);
    if (!mounted || !proceed) {
      return;
    }

    await _deleteSegment(segment);
  }

  Future<bool> _handleRemoteSubmissionCancellation(SegmentInfo segment) async {
    if (!segment.isMarkedPublic) {
      return true;
    }

    final shouldWithdraw =
        await _showCancelRemoteSubmissionDialog(context, segment);
    if (!mounted) {
      return false;
    }

    if (shouldWithdraw != true) {
      return true;
    }

    final messenger = ScaffoldMessenger.of(context);

    AuthController auth;
    try {
      auth = context.read<AuthController>();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to withdraw the public submission.'),
        ),
      );
      return false;
    }

    if (!auth.isLoggedIn || !auth.isConfigured) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please sign in to withdraw the public submission.'),
        ),
      );
      return false;
    }

    final userId = auth.currentUserId;
    final client = auth.client;
    if (userId == null || userId.isEmpty || client == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to withdraw the public submission.'),
        ),
      );
      return false;
    }

    final remoteService = RemoteSegmentsService(client: client);

    try {
      final deleted = await remoteService.deletePendingSubmission(
        addedByUserId: userId,
        name: segment.name,
        startCoordinates: segment.start,
        endCoordinates: segment.end,
      );

      if (deleted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Segment ${segment.displayId} will no longer be reviewed for public release.',
            ),
          ),
        );
      }

      return true;
    } on RemoteSegmentsServiceException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return false;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel the public review for this segment.'),
        ),
      );
      return false;
    }
  }

  Future<void> _deleteSegment(SegmentInfo segment) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final deleted = await _localSegmentsService.deleteLocalSegment(segment.id);
      if (!mounted) {
        return;
      }

      if (!deleted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to delete the segment.')),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Segment ${segment.displayId} deleted.')),
      );
      _segmentsUpdated = true;
      setState(() {
        _segmentsFuture = _repository.loadSegments(onlyLocal: true);
      });
    } on LocalSegmentsServiceException catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete the segment.')),
      );
    }
  }
}


class _EmptySegmentsView extends StatelessWidget {
  const _EmptySegmentsView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No segments available.'));
  }
}

class _EmptyLocalSegmentsView extends StatelessWidget {
  const _EmptyLocalSegmentsView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No local segments saved yet.'));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Failed to load segments.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

Future<_SegmentAction?> _showSegmentActionsSheet(
  BuildContext context,
  SegmentInfo segment,
) {
  final canDelete = segment.isLocalOnly;
  return showModalBottomSheet<_SegmentAction>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete segment'),
              subtitle: canDelete
                  ? null
                  : const Text('Only local segments can be deleted.'),
              enabled: canDelete,
              onTap: canDelete
                  ? () => Navigator.of(context).pop(_SegmentAction.delete)
                  : null,
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> _showDeleteConfirmationDialog(
  BuildContext context,
  SegmentInfo segment,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete segment'),
        content: Text('Are you sure you want to delete segment ${segment.displayId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<bool> _showCancelRemoteSubmissionDialog(
  BuildContext context,
  SegmentInfo segment,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Withdraw public submission?'),
        content: const Text(
          'You have submitted this segment for review. '
          'Do you want to withdraw the submission?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
