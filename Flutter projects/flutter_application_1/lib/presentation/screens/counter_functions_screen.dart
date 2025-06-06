import 'package:flutter/material.dart';

class CounterFunctionsScreen extends StatefulWidget {
  const CounterFunctionsScreen({super.key});

  @override
  State<CounterFunctionsScreen> createState() => _CounterFunctionsScreenState();
}

class _CounterFunctionsScreenState extends State<CounterFunctionsScreen> {
  int clickCounter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter Functions'), centerTitle: true),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomButton(
            icon: Icons.refresh,
            onPressed: () {
              clickCounter = 0;
              setState(() {});
            },
          ),
          const SizedBox(height: 10),
          CustomButton(
            icon: Icons.plus_one,
            onPressed: () {
              // Increment the counter
              clickCounter++;
              setState(() {});
            },
          ),
          const SizedBox(height: 10),
          CustomButton(
            icon: Icons.exposure_minus_1,
            onPressed: () {
              // Decrement the counter
              if (clickCounter > 0) {
                clickCounter--;
                setState(() {}); 
              }
            },
          ),
        ],
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const CustomButton({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(onPressed: onPressed, child: Icon(icon));
  }
}
