import 'package:ecotrash/features/education/domain/entities/education_article.dart';
import 'package:ecotrash/core/services/points_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EducationQuizPage extends ConsumerStatefulWidget {
  const EducationQuizPage({super.key});

  @override
  ConsumerState<EducationQuizPage> createState() => _EducationQuizPageState();
}

class _EducationQuizPageState extends ConsumerState<EducationQuizPage> {
  final List<int?> _answers = List.filled(QuizQuestion.questions.length, null);
  final _scrollController = ScrollController();
  bool _submitted = false;

  int get _score => QuizQuestion.questions
      .asMap()
      .entries
      .where((entry) => _answers[entry.key] == entry.value.correctIndex)
      .length;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Kuis Pilah Sampah',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Jawab lima pertanyaan untuk menguji pemahamanmu.'),
        const SizedBox(height: 16),
        if (_submitted)
          Card(
            key: const Key('education-quiz-result'),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                label:
                    'Skor kuis $_score dari ${QuizQuestion.questions.length}',
                child: Text(
                  'Skor kamu: $_score dari ${QuizQuestion.questions.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
        for (var index = 0; index < QuizQuestion.questions.length; index++)
          _buildQuestion(index),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('education-quiz-submit'),
          onPressed: _submitted ? _reset : _submit,
          child: Text(_submitted ? 'Ulangi kuis' : 'Lihat skor'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildQuestion(int index) => _QuestionCard(
    questionIndex: index,
    question: QuizQuestion.questions[index],
    selectedAnswer: _answers[index],
    submitted: _submitted,
    onChanged: (answer) => setState(() => _answers[index] = answer),
  );

  Future<void> _submit() async {
    if (_answers.any((answer) => answer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jawab semua pertanyaan terlebih dahulu.'),
        ),
      );
      return;
    }
    setState(() => _submitted = true);
    if (_score == QuizQuestion.questions.length) {
      final now = DateTime.now();
      final referenceId =
          'perfect-${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      try {
        await ref
            .read(pointsServiceProvider)
            .awardQuizBonus(referenceId: referenceId);
        ref
          ..invalidate(pointsBalanceProvider)
          ..invalidate(lifetimePointsProvider)
          ..invalidate(pointsTransactionsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bonus kuis +10 poin berhasil!')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bonus kuis gagal dicatat: $error')),
          );
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _reset() {
    setState(() {
      _answers.fillRange(0, _answers.length, null);
      _submitted = false;
    });
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.questionIndex,
    required this.question,
    required this.selectedAnswer,
    required this.submitted,
    required this.onChanged,
  });

  final int questionIndex;
  final QuizQuestion question;
  final int? selectedAnswer;
  final bool submitted;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedAnswer == question.correctIndex;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${questionIndex + 1}. ${question.question}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (
                  var optionIndex = 0;
                  optionIndex < question.options.length;
                  optionIndex++
                )
                  ChoiceChip(
                    key: Key('education-answer-$questionIndex-$optionIndex'),
                    label: Text(question.options[optionIndex]),
                    selected: selectedAnswer == optionIndex,
                    onSelected: submitted
                        ? null
                        : (selected) {
                            if (selected) {
                              onChanged(optionIndex);
                            }
                          },
                  ),
              ],
            ),
            if (submitted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${isCorrect ? 'Benar.' : 'Jawaban yang tepat: ${question.options[question.correctIndex]}.'} '
                  '${question.explanation}',
                  style: TextStyle(
                    color: isCorrect
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
