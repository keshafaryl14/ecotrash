import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/education/domain/entities/education_article.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EducationArticlePage extends StatelessWidget {
  const EducationArticlePage({required this.article, super.key});

  final EducationArticle article;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Chip(
          avatar: Icon(
            switch (article.category) {
              EducationCategory.organic => Icons.compost_outlined,
              EducationCategory.inorganic => Icons.recycling_outlined,
              EducationCategory.hazardous => Icons.warning_amber_outlined,
            },
            size: 18,
            color: colorScheme.primary,
          ),
          label: Text(article.category.label),
        ),
        const SizedBox(height: 12),
        Text(article.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${article.readingMinutes} menit baca',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 20),
        Text(article.content, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Text(
          'Langkah yang bisa dilakukan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < article.steps.length; index++)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(article.steps[index]),
            ),
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.educationQuiz),
          icon: const Icon(Icons.quiz_outlined),
          label: const Text('Uji pemahaman dengan kuis'),
        ),
      ],
    );
  }
}

class EducationArticleNotFoundPage extends StatelessWidget {
  const EducationArticleNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.article_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Artikel tidak ditemukan.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go(AppRoutes.education),
            child: const Text('Kembali ke edukasi'),
          ),
        ],
      ),
    ),
  );
}
