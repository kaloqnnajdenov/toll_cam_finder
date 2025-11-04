class BulgarianVoiceCooldown {
  BulgarianVoiceCooldown._();

  static DateTime? _lastExitVoiceAt;

  static void markExitVoicePlayed() {
    _lastExitVoiceAt = DateTime.now();
  }

  static bool isExitVoiceCoolingDown(Duration hold) {
    final DateTime? last = _lastExitVoiceAt;
    if (last == null) {
      return false;
    }
    return DateTime.now().difference(last) < hold;
  }
}
