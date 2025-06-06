import 'package:flutter/material.dart';
import 'package:yes_no_app/domain/entities/message.dart';

class MyMessageBubble extends StatelessWidget {

  final Message message;

  const MyMessageBubble({super.key, required this.message});


  @override
  Widget build(BuildContext context) {

    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(color: colors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(20.0),
              )),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text(
              message.text,
              style: TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
