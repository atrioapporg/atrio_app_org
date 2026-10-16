class PostModel {
  final int id;
  final String title;
  final String content;
  final String imageUrl;
  final String videoUrl;
  final String linkUrl;
  final bool allowComments;
  final String audience;
  final String publishDate;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.videoUrl,
    required this.linkUrl,
    required this.allowComments,
    required this.audience,
    required this.publishDate,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
      linkUrl: json['link_url'] as String? ?? '',
      allowComments: json['allow_comments'] as bool? ?? false,
      audience: json['audience'] as String? ?? 'todos',
      publishDate: json['publish_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'image_url': imageUrl,
    'video_url': videoUrl,
    'link_url': linkUrl,
    'allow_comments': allowComments,
    'audience': audience,
    'publish_date': publishDate,
  };

  /// Devuelve el contenido sin etiquetas HTML ni espacios redundantes.
  String get plainContent {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
