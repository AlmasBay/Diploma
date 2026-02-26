import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/news_portal.dart';
import '../screens/news/news_detail_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class NewsCard extends StatefulWidget {
  final NewsPortal news;
  final VoidCallback? onRefresh;

  const NewsCard({
    super.key,
    required this.news,
    this.onRefresh,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _isFavorite = false;
  bool _isLoading = false;

  String _domainFromUrl(String url) {
    try {
      var u = url.trim();
      if (u.isEmpty) return '';
      if (!u.startsWith('http')) u = 'https://$u';
      final uri = Uri.parse(u);
      final host = uri.host.replaceFirst('www.', '');
      return host.isEmpty ? url : host;
    } catch (_) {
      // если url не парсится — покажем как есть, но коротко
      return url;
    }
  }

  Future<void> _toggleFavorite() async {
    final auth = context.read<AuthService>();
    final userId = await auth.getStoredUserId() ?? auth.userId;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, войдите в систему')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // toggleFavorite уже возвращает bool (true=добавлено, false=удалено)
      final bool newState =
      await ApiService().toggleFavorite(userId, widget.news.id!);

      setState(() => _isFavorite = newState);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Добавлено в избранное 💖' : 'Удалено из избранного',
          ),
        ),
      );

      widget.onRefresh?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final title = widget.news.title.trim();
    final desc = widget.news.description.trim();
    final url = widget.news.url.trim();
    final domain = _domainFromUrl(url);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Theme.of(context).cardTheme.color ?? scheme.surface,
        shape: Theme.of(context).cardTheme.shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewsDetailScreen(news: widget.news),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withOpacity(0.55),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Верхняя строка: категория + избранное
                Row(
                  children: [
                    if (widget.news.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.news.category!.name,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    const Spacer(),
                    InkResponse(
                      onTap: _isLoading ? null : _toggleFavorite,
                      radius: 22,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _isLoading
                            ? SizedBox(
                          key: const ValueKey('loading'),
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: scheme.primary,
                          ),
                        )
                            : Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(_isFavorite),
                          color: _isFavorite
                              ? scheme.error
                              : scheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Заголовок
                Text(
                  title.isEmpty ? 'Без названия' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),

                const SizedBox(height: 10),

                // Описание
                if (desc.isNotEmpty)
                  Text(
                    desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: scheme.onSurface.withOpacity(0.70),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                const SizedBox(height: 14),

                // Нижняя строка: домен + стрелка
                Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: scheme.onSurface.withOpacity(0.45),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        domain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: scheme.onSurface.withOpacity(0.35),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
