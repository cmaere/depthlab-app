class SharedImage {
  final String path;
  final String fileName;
  final String? base64Data;
  final DateTime receivedAt;

  SharedImage({
    required this.path,
    required this.fileName,
    this.base64Data,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  SharedImage copyWith({
    String? path,
    String? fileName,
    String? base64Data,
    DateTime? receivedAt,
  }) {
    return SharedImage(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      base64Data: base64Data ?? this.base64Data,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  @override
  String toString() {
    return 'SharedImage(path: $path, fileName: $fileName, receivedAt: $receivedAt)';
  }
}