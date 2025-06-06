import 'dart:convert';

import 'package:yes_no_app/domain/entities/message.dart';
import 'package:http/http.dart' as https;

class GetYesNoAnswer {
  Future<Message> getAnswer() async {
    var url = Uri.https('yesno.wtf', '/api');
    var response = await https.get(url);

    final Map<String, dynamic> data = jsonDecode(response.body);

    final String answer   = data['answer'];          // "yes" o "no"
    final String imageUrl = data['image'];  // URL de la imagen


    return Message(
      text: answer,          // o traduce a 'sí' / 'no' si quieres
      imageUrl: imageUrl,
      fromWho: FromWho.bot,
    );
  }
}
