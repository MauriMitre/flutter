
import 'dart:io';

void main() {
  greetEveryone();
  print (greetEveryone());
  print('Suma: ${addTwoNumbers(5, 10)}');
  print('Suma con valores opcionales: ${addTwoNumbersOptional(5)}');

} 

String greetEveryone(){
  return 'hello everyone';
}

int addTwoNumbers(int a, int b) => a + b;

int addTwoNumbersOptional([int a = 0, int b = 0]) {
  return a + b;
}

String greetPerson ({required String name, String message = ' hola,'}){
  return ' $message Fernando';
}