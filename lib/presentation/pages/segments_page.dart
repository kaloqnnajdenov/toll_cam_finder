import 'package:flutter/material.dart';

import 'package:toll_cam_finder/services/segments_repository.dart';

import '../../app/app_routes.dart';

class SegmentsPage extends StatefulWidget {
  const SegmentsPage({super.key});

  @override
  State<SegmentsPage> createState() => _SegmentsPageState();
}

class _SegmentsPageState extends State<SegmentsPage> {
  final SegmentsRepository _repository = SegmentsRepository();
  late Future<List<SegmentInfo>> _segmentsFuture;

  @override
  void initState() {
    super.initState();
    _segmentsFuture = _repository.loadSegments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Segments')),
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
              return _SegmentCard(segment: segment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateSegmentPressed,
        icon: const Icon(Icons.add),
        label: const Text('Create segment'),
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

    setState(() {
      _segmentsFuture = _repository.loadSegments();
    });
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({required this.segment});

  final SegmentInfo segment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
                  child: _SegmentLocation(label: 'Start', value: segment.start),
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

class _EmptySegmentsView extends StatelessWidget {
  const _EmptySegmentsView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No segments available.'));
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
