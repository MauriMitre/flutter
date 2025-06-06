import 'package:flutter/material.dart';
import 'package:yes_no_app/domain/entities/message.dart';

class HerMessageBubble extends StatelessWidget {

  final Message message;

  const HerMessageBubble({super.key, required  this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20.0),
              bottomRight: Radius.circular(20.0),
              bottomLeft: Radius.circular(20.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text(
              message.text,
              style: TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
        ),
        const SizedBox(height: 5),
        //ImageBubble(),
        const SizedBox(height: 10),
      ],
    );
  }
}

class ImageBubble extends StatelessWidget {
  const ImageBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: Image.network(
        "https://yesno.wtf/assets/yes/10-271c872c91cd72c1e38e72d2f8eda676.gif",
        width: size.width * 0.6,
        height: 150,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Text(
            'Image not available',
            style: TextStyle(color: Colors.red, fontSize: 16.0),
          ),
      ),
    ));
  }
}
