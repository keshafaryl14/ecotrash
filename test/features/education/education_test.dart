import 'package:ecotrash/features/education/domain/entities/education_article.dart';
import 'package:ecotrash/features/education/presentation/education_article_page.dart';
import 'package:ecotrash/features/education/presentation/education_page.dart';
import 'package:ecotrash/features/education/presentation/education_quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('filters articles and opens article details', (tester) async {
    final router = GoRouter(
      initialLocation: '/education',
      routes: [
        GoRoute(
          path: '/education',
          builder: (context, state) => const Scaffold(body: EducationPage()),
        ),
        GoRoute(
          path: '/education/article/:slug',
          builder: (context, state) => Scaffold(
            body: EducationArticlePage(
              article: EducationArticle.bySlug(state.pathParameters['slug']!)!,
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('education-filter-hazardous')));
    await tester.pumpAndSettle();

    expect(find.text('Baterai bekas termasuk sampah B3'), findsOneWidget);
    expect(find.text('Ubah sisa dapur menjadi kompos'), findsNothing);
    await tester.tap(
      find.byKey(const Key('education-article-baterai-termasuk-b3')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Langkah yang bisa dilakukan'), findsOneWidget);
    expect(
      find.text('Simpan baterai bekas dalam wadah kering dan tertutup.'),
      findsOneWidget,
    );
  });

  testWidgets('scores five answered quiz questions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EducationQuizPage())),
    );
    await tester.pumpAndSettle();

    const correctAnswers = [0, 1, 2, 0, 1];
    for (var question = 0; question < correctAnswers.length; question++) {
      final answer = find.byKey(
        Key('education-answer-$question-${correctAnswers[question]}'),
      );
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(answer).selected, isTrue);
    }
    final submit = find.byKey(const Key('education-quiz-submit'));
    await tester.scrollUntilVisible(submit, 300);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Jawab semua pertanyaan terlebih dahulu.'), findsNothing);
    expect(find.byKey(const Key('education-quiz-result')), findsOneWidget);
    expect(find.textContaining('Skor kamu: 5 dari 5'), findsOneWidget);
  });
}
