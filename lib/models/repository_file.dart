class RepositoryFile {
  final String id;
  final String name;
  final String fileType;
  final DateTime uploadDate;
  final String uploadedBy;
  final String size;
  final String description;

  const RepositoryFile({
    required this.id,
    required this.name,
    required this.fileType,
    required this.uploadDate,
    required this.uploadedBy,
    required this.size,
    required this.description,
  });

  RepositoryFile copyWith({
    String? id,
    String? name,
    String? fileType,
    DateTime? uploadDate,
    String? uploadedBy,
    String? size,
    String? description,
  }) {
    return RepositoryFile(
      id: id ?? this.id,
      name: name ?? this.name,
      fileType: fileType ?? this.fileType,
      uploadDate: uploadDate ?? this.uploadDate,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      size: size ?? this.size,
      description: description ?? this.description,
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
    );
  }
}
