import 'category.dart';

class NewsPortal {
  final int? id;
  final String title;
  final String url;
  final String description;
  final Category? category;

  NewsPortal({
    this.id,
    required this.title,
    required this.url,
    required this.description,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'category': category?.toJson(),
    };
  }

  factory NewsPortal.fromJson(Map<String, dynamic> json) {
    return NewsPortal(
      id: json['id'],
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
    );
  }
}