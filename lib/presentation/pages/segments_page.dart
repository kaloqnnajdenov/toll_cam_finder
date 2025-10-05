import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/services/auth_controller.dart';
import 'package:toll_cam_finder/services/local_segments_service.dart';
import 'package:toll_cam_finder/services/remote_segments_service.dart';
import 'package:toll_cam_finder/services/segments_metadata_service.dart';
import 'package:toll_cam_finder/services/segments_repository.dart';

import '../../app/app_routes.dart';
import '../widgets/add_segment/empty_segments_views.dart';
import '../widgets/add_segment/segment_action_dialogs.dart';
import '../widgets/add_segment/segment_card.dart';
import '../widgets/add_segment/segments_error_view.dart';

class SegmentsPage extends StatefulWidget {
  const SegmentsPage({super.key});

  @override
  State<SegmentsPage> createState() => _SegmentsPageState();
}

class _SegmentsPageState extends State<SegmentsPage> {
  final SegmentsRepository _repository = SegmentsRepository();
  final LocalSegmentsService _localSegmentsService = LocalSegmentsService();
  final SegmentsMetadataService _metadataService = SegmentsMetadataService();
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
              return SegmentsErrorView(
                onRetry: () {
                  setState(() {
                    _segmentsFuture = _repository.loadSegments();
                  });
                },
              );
            }

            final segments = snapshot.data ?? const <SegmentInfo>[];
            if (segments.isEmpty) {
              return const EmptySegmentsView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: segments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final segment = segments[index];
                return SegmentCard(
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
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.localSegments);
    if (!mounted || result != true) {
      return;
    }

    _segmentsUpdated = true;
    setState(() {
      _segmentsFuture = _repository.loadSegments();
    });
  }

  Future<void> _onCreateSegmentPressed() async {
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.createSegment);
    if (!mounted || result != true) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Segment saved locally.')));

    _segmentsUpdated = true;
    setState(() {
      _segmentsFuture = _repository.loadSegments();
    });
  }

  Future<void> _onSegmentLongPress(SegmentInfo segment) async {
    final action = await showSegmentActionsSheet(context, segment);
    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case SegmentAction.delete:
        await _confirmAndDeleteSegment(segment);
        break;
      case SegmentAction.deactivate:
        await _setSegmentDeactivated(segment, true);
        break;
      case SegmentAction.activate:
        await _setSegmentDeactivated(segment, false);
        break;
    }
  }

  Future<void> _setSegmentDeactivated(
    SegmentInfo segment,
    bool deactivate,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _metadataService.setSegmentDeactivated(segment.id, deactivate);
      if (!mounted) return;

      final message = deactivate
          ? 'Segment ${segment.displayId} hidden. Cameras and warnings are disabled.'
          : 'Segment ${segment.displayId} is visible again. Cameras and warnings restored.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
      _segmentsUpdated = true;
      setState(() {
        _segmentsFuture = _repository.loadSegments();
      });
    } on SegmentsMetadataException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update segment ${segment.displayId}: ${error.message}',
          ),
        ),
      );
    }
  }

  Future<void> _confirmAndDeleteSegment(SegmentInfo segment) async {
    final confirmed = await showDeleteConfirmationDialog(context, segment);
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

    final shouldWithdraw = await showCancelRemoteSubmissionDialog(
      context,
      segment,
    );
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
      final status = await remoteService.getSubmissionStatus(
        addedByUserId: userId,
        name: segment.name,
        startCoordinates: segment.startCoordinates,
        endCoordinates: segment.endCoordinates,
      );

      if (status == SegmentSubmissionStatus.approved) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Segment ${segment.displayId} was already approved by the administrators and is public.',
            ),
          ),
        );
        return true;
      }

      if (status == SegmentSubmissionStatus.pending ||
          status == SegmentSubmissionStatus.other) {
        final deleted = await remoteService.deleteSubmission(
          addedByUserId: userId,
          name: segment.name,
          startCoordinates: segment.startCoordinates,
          endCoordinates: segment.endCoordinates,
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
      }

      return true;
    } on RemoteSegmentsServiceException catch (error) {
      if (error.cause is SocketException) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No internet connection. The public submission cannot be withdrawn and the segment will only be deleted locally.',
            ),
          ),
        );
        return true;
      }

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
      final deleted = await _localSegmentsService.deleteLocalSegment(
        segment.id,
      );
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
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
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

class LocalSegmentsPage extends StatefulWidget {
  const LocalSegmentsPage({super.key});

  @override
  State<LocalSegmentsPage> createState() => _LocalSegmentsPageState();
}

class _LocalSegmentsPageState extends State<LocalSegmentsPage> {
  final SegmentsRepository _repository = SegmentsRepository();
  final LocalSegmentsService _localSegmentsService = LocalSegmentsService();
  final SegmentsMetadataService _metadataService = SegmentsMetadataService();
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
              return SegmentsErrorView(
                onRetry: () {
                  setState(() {
                    _segmentsFuture = _repository.loadSegments(onlyLocal: true);
                  });
                },
              );
            }

            final segments = snapshot.data ?? const <SegmentInfo>[];
            if (segments.isEmpty) {
              return const EmptyLocalSegmentsView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: segments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final segment = segments[index];
                return SegmentCard(
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
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.createSegment);
    if (!mounted || result != true) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Segment saved locally.')));

    _segmentsUpdated = true;
    setState(() {
      _segmentsFuture = _repository.loadSegments(onlyLocal: true);
    });
  }

  Future<void> _onSegmentLongPress(SegmentInfo segment) async {
    final action = await showSegmentActionsSheet(context, segment);
    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case SegmentAction.delete:
        await _confirmAndDeleteSegment(segment);
        break;
      case SegmentAction.deactivate:
        await _setSegmentDeactivated(segment, true);
        break;
      case SegmentAction.activate:
        await _setSegmentDeactivated(segment, false);
        break;
    }
  }

  Future<void> _setSegmentDeactivated(
    SegmentInfo segment,
    bool deactivate,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _metadataService.setSegmentDeactivated(segment.id, deactivate);
      if (!mounted) return;

      final message = deactivate
          ? 'Segment ${segment.displayId} hidden. Cameras and warnings are disabled.'
          : 'Segment ${segment.displayId} is visible again. Cameras and warnings restored.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
      _segmentsUpdated = true;
      setState(() {
        _segmentsFuture = _repository.loadSegments(onlyLocal: true);
      });
    } on SegmentsMetadataException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update segment ${segment.displayId}: ${error.message}',
          ),
        ),
      );
    }
  }

  Future<void> _confirmAndDeleteSegment(SegmentInfo segment) async {
    final confirmed = await showDeleteConfirmationDialog(context, segment);
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

    final shouldWithdraw = await showCancelRemoteSubmissionDialog(
      context,
      segment,
    );
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
      final status = await remoteService.getSubmissionStatus(
        addedByUserId: userId,
        name: segment.name,
        startCoordinates: segment.startCoordinates,
        endCoordinates: segment.endCoordinates,
      );

      if (status == SegmentSubmissionStatus.approved) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Segment ${segment.displayId} was already approved by the administrators and is public.',
            ),
          ),
        );
        return true;
      }

      if (status == SegmentSubmissionStatus.pending ||
          status == SegmentSubmissionStatus.other) {
        final deleted = await remoteService.deleteSubmission(
          addedByUserId: userId,
          name: segment.name,
          startCoordinates: segment.startCoordinates,
          endCoordinates: segment.endCoordinates,
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
      }

      return true;
    } on RemoteSegmentsServiceException catch (error) {
      if (error.cause is SocketException) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No internet connection. The public submission cannot be withdrawn and the segment will only be deleted locally.',
            ),
          ),
        );
        return true;
      }

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
      final deleted = await _localSegmentsService.deleteLocalSegment(
        segment.id,
      );
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
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
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
