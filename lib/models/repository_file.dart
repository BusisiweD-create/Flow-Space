class RepositoryFile {
  final String id;
  final String name;
  final String uploader;
  final double size; // in MB
  final DateTime uploadDate;
  final String description;
  final String fileType;

  const RepositoryFile({
    required this.id,
    required this.name,
    required this.uploader,
    required this.size,
    required this.uploadDate,
    required this.description,
    required this.fileType,
  });

  RepositoryFile copyWith({
    String? id,
    String? name,
    String? uploader,
    double? size,
    DateTime? uploadDate,
    String? description,
    String? fileType,
  }) {
    return RepositoryFile(
      id: id ?? this.id,
      name: name ?? this.name,
      uploader: uploader ?? this.uploader,
      size: size ?? this.size,
      uploadDate: uploadDate ?? this.uploadDate,
      description: description ?? this.description,
      fileType: fileType ?? this.fileType,
    );
  }
}
