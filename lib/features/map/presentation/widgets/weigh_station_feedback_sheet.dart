import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/weigh_station_controller.dart';

typedef WeighStationVoteHandler = WeighStationVotes Function(bool isUpvote);

class WeighStationFeedbackSheet extends StatefulWidget {
  const WeighStationFeedbackSheet({
    super.key,
    required this.stationId,
    required this.initialVotes,
    required this.onVote,
    required this.hasVoted,
  });

  final String stationId;
  final WeighStationVotes initialVotes;
  final WeighStationVoteHandler onVote;
  final bool hasVoted;

  @override
  State<WeighStationFeedbackSheet> createState() =>
      _WeighStationFeedbackSheetState();
}

class _WeighStationFeedbackSheetState
    extends State<WeighStationFeedbackSheet> {
  late WeighStationVotes _votes;
  bool _isProcessing = false;
  late bool _hasVoted;

  @override
  void initState() {
    super.initState();
    _votes = widget.initialVotes;
    _hasVoted = widget.hasVoted;
  }

  void _handleVote(bool isUpvote) {
    if (_isProcessing || _hasVoted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final WeighStationVotes updated = widget.onVote(isUpvote);

    if (!mounted) {
      return;
    }

    setState(() {
      _votes = updated;
      _isProcessing = false;
      _hasVoted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.weighStationFeedbackTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.weighStationIdentifier(widget.stationId),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.weighStationUpvoteCount(_votes.upvotes),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.weighStationDownvoteCount(
                      _votes.downvotes,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing || _hasVoted
                        ? null
                        : () => _handleVote(true),
                    icon: const Icon(Icons.thumb_up),
                    label: Text(localizations.weighStationUpvoteAction),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing || _hasVoted
                        ? null
                        : () => _handleVote(false),
                    icon: const Icon(Icons.thumb_down),
                    label: Text(localizations.weighStationDownvoteAction),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
