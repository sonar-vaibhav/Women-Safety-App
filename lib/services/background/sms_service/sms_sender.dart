// Temporary stub: background SMS sending is disabled while
// the legacy background_sms plugin is removed for compatibility.
class SMSSender {
  Future<void> sendAndNavigate(
      Object context, String message, List<String> recipients) async {
    // No-op for now. Integrate a modern SMS solution here if needed.
  }
}
