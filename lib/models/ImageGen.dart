class ImageGeneration {
  final String prompt;
  final String url;
  final String userId;
  final DateTime createdAt;

  ImageGeneration({
    required this.prompt,

    required this.url,
    required this.userId,
    required this.createdAt,
  });

  factory ImageGeneration.fromJson(Map<String, dynamic> json) {
    return ImageGeneration(
      prompt: json['prompt'] as String,
      url: json['url'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'url': url,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
