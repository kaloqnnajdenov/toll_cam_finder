class WeighStationVotes {
  const WeighStationVotes({
    this.upvotes = 0,
    this.downvotes = 0,
  });

  final int upvotes;
  final int downvotes;

  static const empty = WeighStationVotes();

  WeighStationVotes copyWith({int? upvotes, int? downvotes}) {
    return WeighStationVotes(
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
    );
  }
}

class WeighStationVoteResult {
  const WeighStationVoteResult({
    required this.votes,
    required this.userVote,
  });

  final WeighStationVotes votes;
  final bool? userVote;
}
