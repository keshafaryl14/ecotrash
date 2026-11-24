import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/education/domain/entities/education_article.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  EducationCategory? _category;

  @override
  Widget build(BuildContext context) {
    final articles = EducationArticle.articles
        .where((article) => _category == null || article.category == _category)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Edukasi Pilah Sampah',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Panduan singkat agar sampah lebih mudah diolah kembali.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          key: const Key('education-start-quiz'),
          onPressed: () => context.push(AppRoutes.educationQuiz),
          icon: const Icon(Icons.quiz_outlined),
          label: const Text('Ikuti kuis 5 pertanyaan'),
        ),
        const SizedBox(height: 20),
        Text('Kategori', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              key: const Key('education-filter-all'),
              label: const Text('Semua'),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
            for (final category in EducationCategory.values)
              FilterChip(
                key: Key('education-filter-${category.name}'),
                label: Text(category.label),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (articles.isEmpty)
          const _EducationEmptyState()
        else
          for (final article in articles)
            _EducationArticleCard(
              article: article,
              onTap: () => context.push(
                AppRoutes.educationArticle.replaceFirst(':slug', article.slug),
              ),
            ),
      ],
    );
  }
}

class _EducationArticleCard extends StatelessWidget {
  const _EducationArticleCard({required this.article, required this.onTap});

  final EducationArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Semantics(
        button: true,
        label:
            '${article.category.label}: ${article.title}, '
            '${article.readingMinutes} menit baca',
        child: InkWell(
          key: Key('education-article-${article.slug}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(
                    _categoryIcon(article.category),
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.category.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.summary,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${article.readingMinutes} menit baca',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(EducationCategory category) => switch (category) {
    EducationCategory.organic => Icons.compost_outlined,
    EducationCategory.inorganic => Icons.recycling_outlined,
    EducationCategory.hazardous => Icons.warning_amber_outlined,
  };
}

class _EducationEmptyState extends StatelessWidget {
  const _EducationEmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(Icons.menu_book_outlined, size: 44),
        SizedBox(height: 12),
        Text('Belum ada artikel pada kategori ini.'),
      ],
    ),
  );
}
