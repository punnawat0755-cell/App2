class EntryFlowGuard {
  EntryFlowGuard._();

  static DateTime? _ignoreResumeUntil;

  static void ignoreResumeFor(Duration duration) {
    final nextDeadline = DateTime.now().add(duration);
    final currentDeadline = _ignoreResumeUntil;

    if (currentDeadline == null || nextDeadline.isAfter(currentDeadline)) {
      _ignoreResumeUntil = nextDeadline;
    }
  }

  static bool get shouldIgnoreResume {
    final deadline = _ignoreResumeUntil;
    if (deadline == null) {
      return false;
    }

    final now = DateTime.now();
    if (now.isBefore(deadline)) {
      return true;
    }

    _ignoreResumeUntil = null;
    return false;
  }
}
