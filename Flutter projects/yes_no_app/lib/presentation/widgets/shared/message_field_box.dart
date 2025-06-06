import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yes_no_app/presentation/providers/chat_provider.dart';

class MessageFieldBox extends StatelessWidget {
  const MessageFieldBox({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final textController = TextEditingController();
    final FocusNode focusNode = FocusNode();

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
          // Handle message sending logic here
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
        if (value.isNotEmpty) {
          textController.clear();
          focusNode.requestFocus();
        }
      },
      /* onChanged: (value) {
        // Optionally handle text changes
        print('changed: $value');
      }, */
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
