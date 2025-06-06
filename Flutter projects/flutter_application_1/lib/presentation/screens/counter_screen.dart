import 'package:flutter/material.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int clickCounter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scada Digicom')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Hola buenas Tardes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w100),
            ),
            Text(
              '$clickCounter',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w100,
                color: Colors.black,
              ),
            ),
            Text(
              clickCounter <= 1 ? 'Click' : 'Clicks',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action to perform when the button is pressed
          setState(() {
            clickCounter++;
          });
          /* ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Floating Action Button Pressed')),
          ); */
        },
        tooltip: 'Increment',
        child: const Icon(Icons.plus_one),
      ),
    );
  }
}
