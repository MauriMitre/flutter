import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yes_no_app/presentation/providers/chat_provider.dart';

class MessageFieldBox extends StatefulWidget {
  const MessageFieldBox({super.key});

  @override
  State<MessageFieldBox> createState() => _MessageFieldBoxState();
}

class _MessageFieldBoxState extends State<MessageFieldBox> {
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final outlineInputBorder = UnderlineInputBorder(
      borderRadius: BorderRadius.circular(40.0),
      borderSide: BorderSide(color: colors.primary),
    );

    final inputDecoration = InputDecoration(
      filled: true,
      enabledBorder: outlineInputBorder,
      focusedBorder: outlineInputBorder,
      hintText: 'Type a message',
      border: InputBorder.none,
    );

    final iconButton = IconButton(
      icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
      onPressed: () {
        final message = textController.value.text.trim();
        if (message.isNotEmpty) {
          context.read<ChatProvider>().sendMessage(message);
          textController.clear();
        }
      },
    );

    final textFormField = TextFormField(
      focusNode: focusNode,
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
      decoration: inputDecoration,
      controller: textController,
      onFieldSubmitted: (value) {
        final message = value.trim();
        if (message.isNotEmpty) {
          context.read<ChatProvider>().sendMessage(message);
          textController.clear();
          focusNode.requestFocus();
        }
      },
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0)),
      child: Row(
        children: [
          Expanded(child: textFormField),
          iconButton,
        ],
      ),
    );
  }
}
