enum WritingMode {
  chat,
  thread;

  String get label {
    switch (this) {
      case WritingMode.chat:
        return '채팅방식';
      case WritingMode.thread:
        return '스레드방식';
    }
  }

  String get storageValue {
    switch (this) {
      case WritingMode.chat:
        return 'chat';
      case WritingMode.thread:
        return 'thread';
    }
  }

  static WritingMode fromStorage(String? value) {
    switch (value?.trim()) {
      case 'thread':
        return WritingMode.thread;
      case 'chat':
      default:
        return WritingMode.chat;
    }
  }
}
