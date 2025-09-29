class RepositoryFile {
  final String id;
  final String name;
  final String fileType;
  final DateTime uploadDate;
  final String uploadedBy;
  final String size;
  final String description;
  final String uploader;
  final double sizeInMB; // in MB

  const RepositoryFile({
    required this.id,
    required this.name,
    required this.fileType,
    required this.uploadDate,
    required this.uploadedBy,
    required this.size,
    required this.description,
    required this.uploader,
    required this.sizeInMB,
  });

  RepositoryFile copyWith({
    String? id,
    String? name,
    String? fileType,
    DateTime? uploadDate,
    String? uploadedBy,
    String? size,
    String? description,
    String? uploader,
    double? sizeInMB,
  }) {
    return RepositoryFile(
      id: id ?? this.id,
      name: name ?? this.name,
      fileType: fileType ?? this.fileType,
      uploadDate: uploadDate ?? this.uploadDate,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      size: size ?? this.size,
      description: description ?? this.description,
      uploader: uploader ?? this.uploader,
      sizeInMB: sizeInMB ?? this.sizeInMB,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fileType': fileType,
      'uploadDate': uploadDate.toIso8601String(),
      'uploadedBy': uploadedBy,
      'size': size,
      'description': description,
      'uploader': uploader,
      'sizeInMB': sizeInMB,
    };
  }

  factory RepositoryFile.fromJson(Map<String, dynamic> json) {
    return RepositoryFile(
      id: json['id'],
      name: json['name'],
      fileType: json['fileType'],
      uploadDate: DateTime.parse(json['uploadDate']),
      uploadedBy: json['uploadedBy'],
      size: json['size'],
      description: json['description'],
      uploader: json['uploader'] ?? '',
      sizeInMB: json['sizeInMB']?.toDouble() ?? 0.0,
    );
  }
}
