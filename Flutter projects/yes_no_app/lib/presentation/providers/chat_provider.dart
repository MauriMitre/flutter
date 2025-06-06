import 'package:flutter/material.dart';
import 'package:yes_no_app/CONFIG/helpers/get_yes_no_answer.dart';
import 'package:yes_no_app/domain/entities/message.dart';

class ChatProvider extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final GetYesNoAnswer getYesNoAnswer = GetYesNoAnswer();

  List<Message> messages = [
    Message(
      text: 'Hello, how can I help you?',
      imageUrl: null,
      fromWho: FromWho.bot,
    ),
    Message(
      text: 'I need some information about your services.',
      imageUrl: null,
      fromWho: FromWho.user,
    ),
  ];

  Future<void> sendMessage(String messageText) async {
    if (messageText.isEmpty) return;

    final newMessage = Message(
      text: messageText,
      imageUrl: null,
      fromWho: FromWho.user,
    );

    messages.add(newMessage);
    notifyListeners();

    // Simulate a response from the bot
    await Future.delayed(Duration(seconds: 1));

    /*  final botResponse = Message(
      text: 'Thank you for your message!',
      imageUrl: null,
      fromWho: FromWho.bot,
    ); */

    if (messageText.endsWith('?')) {
      herReply();
    }
    /* messages.add(botResponse); */
    notifyListeners();
    moveScrollToBottom();
  }

  void moveScrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> herReply() async {
    final response = await getYesNoAnswer.getAnswer();
    messages.add(response);
    notifyListeners();

    moveScrollToBottom();
  }
}
