// features/play/quiz_view.dart — 퀴즈 (정답 검증 + 실패 힌트 단계). 정답 시 pop(true).
import 'package:flutter/material.dart';
import '../../design_system/candy_button.dart';
import '../../design_system/duo_tokens.dart';
import '../../game/game_engine.dart';
import '../../models/mission_item.dart';

class QuizView extends StatefulWidget {
  final MissionItem item;
  final GameEngine engine;
  const QuizView({super.key, required this.item, required this.engine});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  final _answer = TextEditingController();
  String? _hint;

  String get _question =>
      widget.item.quizzes.isNotEmpty ? widget.item.quizzes.first.quiz : '(퀴즈 없음)';
  String get _correct =>
      widget.item.quizzes.isNotEmpty ? widget.item.quizzes.first.answer : '';

  void _submit() {
    final input = _answer.text.trim();
    if (input.toLowerCase() == _correct.trim().toLowerCase() && _correct.isNotEmpty) {
      Navigator.pop(context, true);
      return;
    }
    final fail = widget.engine.quizFailCount(widget.item) + 1;
    widget.engine.recordQuizFailure(widget.item, 1);
    setState(() {
      // 실패 힌트: 1회=글자수, 2회+=첫 글자.
      if (fail >= 2 && _correct.isNotEmpty) {
        _hint = '첫 글자: "${_correct.characters.first}" (${_correct.characters.length}자)';
      } else {
        _hint = '정답은 ${_correct.characters.length}자입니다';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('퀴즈')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 12),
          Text(_question, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 20, color: DuoColors.eel2)),
          const SizedBox(height: 20),
          TextField(
            controller: _answer,
            autofocus: true,
            decoration: const InputDecoration(labelText: '정답', border: OutlineInputBorder()),
            onSubmitted: (_) => _submit(),
          ),
          if (_hint != null) ...[
            const SizedBox(height: 10),
            Text(_hint!, style: const TextStyle(color: DuoColors.fox, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          CandyButton(label: '제출', onPressed: _submit),
        ]),
      ),
    );
  }
}
