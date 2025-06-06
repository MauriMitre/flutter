class YesNoModel {
  String answer;
  String image;
  String forced;

  YesNoModel({required this.answer, required this.image, required this.forced});

  YesNoModel.fromJson(Map<String, dynamic> json)
    : answer = json['answer'],
      image = json['image'],
      forced = json['forced'] ?? '';
}
