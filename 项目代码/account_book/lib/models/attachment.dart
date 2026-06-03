class Attachment {
  final String id;
  final String transactionId;
  final String filename;
  final String filepath;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.transactionId,
    required this.filename,
    required this.filepath,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
  });

  bool get isImage => mimeType.startsWith('image/');

  Attachment copyWith({
    String? filename,
    String? filepath,
    String? mimeType,
    int? sizeBytes,
  }) {
    return Attachment(
      id: id,
      transactionId: transactionId,
      filename: filename ?? this.filename,
      filepath: filepath ?? this.filepath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transactionId': transactionId,
    'filename': filename,
    'filepath': filepath,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'] as String,
    transactionId: json['transactionId'] as String,
    filename: json['filename'] as String,
    filepath: json['filepath'] as String,
    mimeType: json['mimeType'] as String,
    sizeBytes: json['sizeBytes'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
