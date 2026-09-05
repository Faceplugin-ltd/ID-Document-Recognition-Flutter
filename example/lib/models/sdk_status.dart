enum SdkPhase { loading, ready, error }

class SdkStatus {
  const SdkStatus({
    required this.phase,
    required this.message,
    this.machine = '',
  });

  final SdkPhase phase;
  final String message;
  final String machine;

  bool get ready => phase == SdkPhase.ready;
}
