class ConcernMessage {
  final String userId;
  final String userName;
  final String subject;
  final String message;
  String? adminResponse;

  ConcernMessage({
    required this.userId,
    required this.userName,
    required this.subject,
    required this.message,
    this.adminResponse,
  });
}

// Shared list for demo purposes
List<ConcernMessage> allMessages = [];
