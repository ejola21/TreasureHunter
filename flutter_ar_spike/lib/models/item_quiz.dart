// models/item_quiz.dart — ItemQuiz.swift 이식.
class ItemQuiz {
  final String missionID;
  final int itemID;
  final int seq;
  String quiz;
  String answer;
  final int probability;

  ItemQuiz({
    this.missionID = '',
    this.itemID = 0,
    this.seq = 0,
    this.quiz = '',
    this.answer = '',
    this.probability = 0,
  });

  String get id => '${missionID}_${itemID}_$seq';

  factory ItemQuiz.fromJson(Map<String, dynamic> j) => ItemQuiz(
        missionID: j['MissionID'] as String? ?? '',
        itemID: (j['ItemID'] as num?)?.toInt() ?? 0,
        seq: (j['Seq'] as num?)?.toInt() ?? 0,
        quiz: j['Quiz'] as String? ?? '',
        answer: j['Answer'] as String? ?? '',
        probability: (j['Probability'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'MissionID': missionID,
        'ItemID': itemID,
        'Seq': seq,
        'Quiz': quiz,
        'Answer': answer,
        'Probability': probability,
      };
}
