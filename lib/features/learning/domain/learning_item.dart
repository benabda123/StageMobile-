class LearningItem {
  const LearningItem({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.url,
    required this.channelTitle,
  });

  final String videoId;
  final String title;
  final String description;
  final String thumbnail;
  final String url;
  final String channelTitle;

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    return LearningItem(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      url: json['url'] as String? ?? '',
      channelTitle: json['channelTitle'] as String? ?? '',
    );
  }
}
