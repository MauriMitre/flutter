import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yes_no_app/domain/entities/message.dart';
import 'package:yes_no_app/presentation/providers/chat_provider.dart';
import 'package:yes_no_app/presentation/widgets/chat/her_message_bubble.dart';
import 'package:yes_no_app/presentation/widgets/chat/my_message_buble.dart';
import 'package:yes_no_app/presentation/widgets/shared/message_field_box.dart';

class ChatScreen extends StatelessWidget {
  final String chatTitle;
  const ChatScreen({super.key, this.chatTitle = 'Angelina Jolie'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(chatTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                "https://i.guim.co.uk/img/static/sys-images/Film/Pix/pictures/2002/04/30/life1.jpg?width=465&dpr=1&s=none&crop=none",
              ),
            ),
          ),
        ],
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: _ChatView(),
      ),
    );
  }
}

class _ChatView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: chatProvider.scrollController,
                itemCount: chatProvider.messages.length,
                itemBuilder: (context, index) {
                  final message = chatProvider.messages[index];
                  if (message.fromWho == FromWho.user) {
                    return MyMessageBubble(message: message);
                  } else {
                    return HerMessageBubble(message: message);
                  }
                },
              ),
            ),
            MessageFieldBox(),
          ],
        ),
      ),
    );
  }
}
